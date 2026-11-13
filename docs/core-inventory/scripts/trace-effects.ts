// Statically traces what each core route does, starting from its Fastify registration.
//
// Run from the core repo root, after dump-routes.ts:
//   ts-node --transpile-only <this file> <routes.json> <out.json>
//
// For every route it walks the registration call (handler, inline preHandlers), then
// follows every call the TypeScript checker can resolve into core's src: services,
// repositories, interface implementations and service hooks (setPreHook/setPostHook
// handlers reached through runPreHooks/runPostHooks). Along the way it records:
//   - tables read / written (Drizzle table references; insert/update/delete = write)
//   - websocket publications, emails, file storage, search index, jobs, external services
//   - the service methods the handler calls directly (entry points for the spec)
//   - the service hooks fired along the way that have handlers registered
//
// Limits: calls through `any`, dynamic dispatch the checker cannot resolve, and code
// reached only through events other than the HookManager are not followed.
import { readFileSync, writeFileSync } from 'node:fs';
import { join, relative } from 'node:path';

const CORE = process.cwd();
// eslint-disable-next-line @typescript-eslint/no-require-imports
const ts: typeof import('typescript') = require(join(CORE, 'node_modules/typescript'));

const [routesPath, outPath] = process.argv.slice(2);
type Route = { method: string; url: string; source: string | null; [k: string]: unknown };
const routes: Route[] = JSON.parse(readFileSync(routesPath, 'utf8'));

// --- program -------------------------------------------------------------------------
const cfgPath = join(CORE, 'tsconfig.json');
const cfg = ts.getParsedCommandLineOfConfigFile(cfgPath, {}, {
  ...ts.sys,
  onUnRecoverableConfigFileDiagnostic: (d) => {
    throw new Error(ts.flattenDiagnosticMessageText(d.messageText, '\n'));
  },
})!;
const program = ts.createProgram(cfg.fileNames, cfg.options);
const checker = program.getTypeChecker();

const SRC = join(CORE, 'src') + '/';
const isTestFile = (f: string) => /\.(spec|test)\.ts$|\/test\/|\/__mocks__\//.test(f);
const isCoreSrc = (f: string) => f.startsWith(SRC) && !f.endsWith('.d.ts') && !isTestFile(f);
const srcFiles = program.getSourceFiles().filter((f) => isCoreSrc(f.fileName));
const rel = (f: string) => relative(CORE, f);

// --- drizzle tables: export name -> SQL name ------------------------------------------
const SCHEMA = join(CORE, 'src/drizzle/schema.ts');
const tableByExport = new Map<string, string>();
{
  const sf = program.getSourceFile(SCHEMA)!;
  sf.forEachChild((st) => {
    if (!ts.isVariableStatement(st)) return;
    for (const d of st.declarationList.declarations) {
      let init = d.initializer;
      // views: pgView('name').as(qb => ...)
      if (init && ts.isCallExpression(init) && ts.isPropertyAccessExpression(init.expression) &&
        init.expression.name.text === 'as' && ts.isCallExpression(init.expression.expression)) {
        init = init.expression.expression;
      }
      if (!init || !ts.isCallExpression(init) || !ts.isIdentifier(init.expression)) continue;
      if (!/^pg(Table|View|MaterializedView)$/.test(init.expression.text)) continue;
      const first = init.arguments[0];
      if (ts.isIdentifier(d.name) && first && ts.isStringLiteral(first)) {
        tableByExport.set(d.name.text, first.text);
      }
    }
  });
}

// --- helpers ---------------------------------------------------------------------------
const resolveAlias = (s: ts.Symbol | undefined) =>
  s && s.flags & ts.SymbolFlags.Alias ? checker.getAliasedSymbol(s) : s;

const className = (n: ts.Node): string | undefined => {
  for (let p: ts.Node | undefined = n; p; p = p.parent) {
    if ((ts.isClassDeclaration(p) || ts.isInterfaceDeclaration(p)) && p.name) return p.name.text;
  }
  return undefined;
};

const fnLabel = (n: ts.Node): string => {
  for (let p: ts.Node | undefined = n; p; p = p.parent) {
    if ((ts.isMethodDeclaration(p) || ts.isMethodSignature(p)) && p.name) {
      return `${className(p) ?? '?'}.${p.name.getText()}`;
    }
    if (ts.isFunctionDeclaration(p) && p.name) return p.name.text;
    if (ts.isPropertyDeclaration(p) && p.name) return `${className(p) ?? '?'}.${p.name.getText()}`;
    if (ts.isVariableDeclaration(p) && ts.isIdentifier(p.name) && p.initializer &&
      (ts.isArrowFunction(p.initializer) || ts.isFunctionExpression(p.initializer))) {
      return p.name.text;
    }
  }
  return rel(n.getSourceFile().fileName);
};

const typeName = (e: ts.Expression) => {
  const t = checker.getTypeAtLocation(e);
  return (t.getSymbol() ?? t.aliasSymbol)?.getName();
};

const pkgOf = (file: string): string | undefined => {
  const i = file.lastIndexOf('/node_modules/');
  if (i < 0) return undefined;
  const parts = file.slice(i + '/node_modules/'.length).split('/');
  const pkg = parts[0].startsWith('@') ? `${parts[0]}/${parts[1]}` : parts[0];
  // types-only packages stand for the runtime package: @types/node-fetch -> node-fetch
  if (!pkg.startsWith('@types/')) return pkg;
  const name = pkg.slice('@types/'.length);
  return name.includes('__') ? `@${name.replace('__', '/')}` : name;
};

const short = (s: string, n = 80) => (s.length > n ? s.slice(0, n - 1) + '…' : s).replace(/\s+/g, ' ');

/** body-carrying node for a declaration, if it has one we can walk */
const walkable = (d: ts.Declaration | undefined): ts.Node | undefined => {
  if (!d) return undefined;
  if (
    (ts.isMethodDeclaration(d) || ts.isFunctionDeclaration(d) || ts.isConstructorDeclaration(d) ||
      ts.isArrowFunction(d) || ts.isFunctionExpression(d) || ts.isGetAccessor(d)) &&
    d.body
  ) {
    return d;
  }
  if ((ts.isPropertyDeclaration(d) || ts.isVariableDeclaration(d)) && d.initializer &&
    (ts.isArrowFunction(d.initializer) || ts.isFunctionExpression(d.initializer))) {
    return d.initializer;
  }
  return undefined;
};

// --- interface implementations: "Iface.method" -> method declarations ------------------
const implementations = new Map<string, ts.Declaration[]>();
for (const sf of srcFiles) {
  sf.forEachChild(function visit(n) {
    if (ts.isClassDeclaration(n) && n.heritageClauses) {
      for (const h of n.heritageClauses) {
        if (h.token !== ts.SyntaxKind.ImplementsKeyword) continue;
        for (const t of h.types) {
          const iface = t.expression.getText();
          for (const m of n.members) {
            if (ts.isMethodDeclaration(m) && m.name) {
              const k = `${iface}.${m.name.getText()}`;
              implementations.set(k, [...(implementations.get(k) ?? []), m]);
            }
          }
        }
      }
    }
    n.forEachChild(visit);
  });
}

// --- hook registrations: "Class:pre|post:event" -> handler nodes -----------------------
const hooks = new Map<string, ts.Node[]>();
const hookTarget = (call: ts.CallExpression, method: RegExp) => {
  const callee = call.expression;
  if (!ts.isPropertyAccessExpression(callee) || !method.test(callee.name.text)) return undefined;
  const hooksExpr = callee.expression;
  if (!ts.isPropertyAccessExpression(hooksExpr) || hooksExpr.name.text !== 'hooks') return undefined;
  const ev = call.arguments[0];
  if (!ev || !ts.isStringLiteralLike(ev)) return undefined;
  const owner =
    hooksExpr.expression.kind === ts.SyntaxKind.ThisKeyword
      ? className(call)
      : typeName(hooksExpr.expression);
  const phase = /Pre/.test(callee.name.text) ? 'pre' : 'post';
  return `${owner}:${phase}:${ev.text}`;
};
for (const sf of srcFiles) {
  sf.forEachChild(function visit(n) {
    if (ts.isCallExpression(n)) {
      const key = hookTarget(n, /^set(Pre|Post)Hook$/);
      const h = n.arguments[1];
      if (key && h) {
        let target: ts.Node | undefined;
        if (ts.isArrowFunction(h) || ts.isFunctionExpression(h)) target = h;
        else target = walkable(resolveAlias(checker.getSymbolAtLocation(h))?.valueDeclaration);
        if (target) hooks.set(key, [...(hooks.get(key) ?? []), target]);
      }
    }
    n.forEachChild(visit);
  });
}

// --- route registration lookup ---------------------------------------------------------
const ROUTE_METHODS = /^(get|post|put|patch|delete|route|all)$/;
const findRegistration = (source: string): ts.CallExpression | undefined => {
  const [file, lineStr] = source.split(':');
  const sf = program.getSourceFile(join(CORE, file));
  if (!sf) return undefined;
  const line = Number(lineStr) - 1;
  let best: ts.CallExpression | undefined;
  sf.forEachChild(function visit(n) {
    if (ts.isCallExpression(n) && ts.isPropertyAccessExpression(n.expression) &&
      ROUTE_METHODS.test(n.expression.name.text)) {
      const a = sf.getLineAndCharacterOfPosition(n.getStart()).line;
      const b = sf.getLineAndCharacterOfPosition(n.getEnd()).line;
      if (a <= line && line <= b) best = n; // keep descending: innermost wins
    }
    n.forEachChild(visit);
  });
  return best;
};

// --- side-effect classification --------------------------------------------------------
type Effects = {
  tablesRead: Set<string>;
  tablesWritten: Set<string>;
  websockets: Set<string>;
  emails: Set<string>;
  storage: Set<string>;
  search: Set<string>;
  jobs: Set<string>;
  external: Set<string>;
  entrypoints: Set<string>;
  hooks: Set<string>;
};
const newEffects = (): Effects => ({
  tablesRead: new Set(), tablesWritten: new Set(), websockets: new Set(), emails: new Set(),
  storage: new Set(), search: new Set(), jobs: new Set(), external: new Set(),
  entrypoints: new Set(), hooks: new Set(),
});

// classes we record and do not walk into
const LEAF_CLASSES = new Set(['WebsocketService', 'MailerService', 'FileService']);
const EXTERNAL_PKGS: Record<string, string> = {
  openai: 'openai',
  '@graasp/etherpad-api': 'etherpad',
  'node-fetch': 'http',
  ioredis: 'redis',
};

// search calls by intent; helpers (getIndex, waitForTask, health…) are ignored
const SEARCH_KIND: Record<string, 'write' | 'query'> = {
  index: 'write', indexOne: 'write', deleteOne: 'write', updateItem: 'write',
  indexIntegrityFix: 'write', addDocuments: 'write', updateDocuments: 'write',
  deleteDocument: 'write', deleteDocuments: 'write', deleteAllDocuments: 'write',
  search: 'query', multiSearch: 'query', findAndCountItems: 'query', searchForFacetValues: 'query',
};

const wsLabel = (call: ts.CallExpression) => {
  const [topic, , msg] = call.arguments;
  let ev = msg ? short(msg.getText(), 40) : '';
  if (msg && ts.isCallExpression(msg)) {
    const lit = msg.arguments.find(ts.isStringLiteralLike);
    ev = `${msg.expression.getText()}${lit ? `(${lit.text})` : ''}`;
  }
  return `${topic?.getText() ?? '?'} ← ${ev}`;
};

function trace(root: ts.Node): Effects {
  const fx = newEffects();
  const seen = new Set<ts.Node>();
  const queue: { node: ts.Node; depth: number }[] = [{ node: root, depth: 0 }];

  const enqueue = (node: ts.Node | undefined, depth: number) => {
    if (node && !seen.has(node) && isCoreSrc(node.getSourceFile().fileName)) {
      seen.add(node);
      queue.push({ node, depth });
    }
  };

  while (queue.length) {
    const { node, depth } = queue.shift()!;
    const visit = (n: ts.Node): void => {
      // skip route schemas: pure data
      if (depth === 0 && ts.isPropertyAssignment(n) && n.name.getText() === 'schema') return;

      // table references
      if (ts.isIdentifier(n)) {
        const sym = resolveAlias(checker.getSymbolAtLocation(n));
        const decl = sym?.valueDeclaration;
        if (decl && decl.getSourceFile().fileName === SCHEMA && ts.isIdentifier(n) &&
          tableByExport.has(n.text) && !ts.isImportSpecifier(n.parent)) {
          const table = tableByExport.get(n.text)!;
          const p = n.parent;
          const write = ts.isCallExpression(p) && p.arguments[0] === n &&
            ts.isPropertyAccessExpression(p.expression) &&
            /^(insert|update|delete)$/.test(p.expression.name.text);
          (write ? fx.tablesWritten : fx.tablesRead).add(table);
        }
      }
      // relational query API: db.query.<exportName>.findMany(...)
      if (ts.isPropertyAccessExpression(n) && ts.isPropertyAccessExpression(n.expression) &&
        n.expression.name.text === 'query' && tableByExport.has(n.name.text)) {
        fx.tablesRead.add(tableByExport.get(n.name.text)!);
      }

      if (ts.isCallExpression(n) || ts.isNewExpression(n)) handleCall(n, depth);
      n.forEachChild(visit);
    };
    visit(node);
  }
  return fx;

  function handleCall(call: ts.CallExpression | ts.NewExpression, depth: number) {
    // hooks fired by a service
    if (ts.isCallExpression(call)) {
      const key = hookTarget(call, /^run(Pre|Post)Hooks$/);
      if (key) {
        const hs = hooks.get(key);
        if (hs) {
          fx.hooks.add(key);
          hs.forEach((h) => enqueue(h, depth + 1));
        }
        return;
      }
    }

    const sig = checker.getResolvedSignature(call);
    let decl = sig?.getDeclaration() as ts.Declaration | undefined;
    if (!decl || !decl.getSourceFile) {
      const sym = resolveAlias(checker.getSymbolAtLocation(
        ts.isPropertyAccessExpression(call.expression) ? call.expression.name : call.expression,
      ));
      decl = sym?.valueDeclaration ?? sym?.declarations?.[0];
    }
    if (!decl || !decl.getSourceFile) return;
    const file = decl.getSourceFile().fileName;
    const cls = className(decl);
    const name = (decl as ts.NamedDeclaration).name?.getText() ?? '';

    // external packages
    const pkg = pkgOf(file);
    if (pkg) {
      if (pkg === 'bullmq' && /^add(Bulk)?$/.test(name) && ts.isCallExpression(call)) {
        const a = call.arguments[0];
        fx.jobs.add(a ? short(a.getText(), 60) : '?');
      } else if (pkg === 'meilisearch') {
        const kind = SEARCH_KIND[name];
        if (kind) fx.search.add(`${kind}:meilisearch.${name}`);
      } else if (pkg.startsWith('@aws-sdk/')) {
        fx.storage.add(`s3:${cls ?? name}`);
      } else if (pkg === 'nodemailer') {
        fx.emails.add(fnLabel(call));
      } else if (EXTERNAL_PKGS[pkg]) {
        fx.external.add(`${EXTERNAL_PKGS[pkg]}${pkg === 'ioredis' ? '' : `:${fnLabel(call)}`}`);
      }
      return;
    }
    if (name === 'fetch' && !isCoreSrc(file)) {
      fx.external.add(`http:${fnLabel(call)}`);
      return;
    }
    if (!isCoreSrc(file)) return;

    // recorded leaves inside core
    if (cls === 'WebsocketService' && /^publish/.test(name) && ts.isCallExpression(call)) {
      fx.websockets.add(wsLabel(call));
      return;
    }
    if (cls === 'MailerService' && /^send/.test(name)) {
      fx.emails.add(fnLabel(call));
      return;
    }
    if (cls === 'FileService') {
      fx.storage.add(`file:${name}`);
      return;
    }
    if (cls && LEAF_CLASSES.has(cls)) return;
    if (cls === 'MeiliSearchWrapper') {
      const kind = SEARCH_KIND[name];
      if (kind) fx.search.add(`${kind}:${name}`);
    }

    if (depth === 0 && cls && /Service$/.test(cls) &&
      (ts.isMethodDeclaration(decl) || ts.isPropertyDeclaration(decl))) {
      fx.entrypoints.add(`${cls}.${name}`);
    }

    // interface method: walk every implementation
    if (ts.isMethodSignature(decl) && cls) {
      (implementations.get(`${cls}.${name}`) ?? []).forEach((m) => enqueue(walkable(m), depth + 1));
      if (cls === 'FileRepository') fx.storage.add(`repo:${name}`);
      return;
    }
    enqueue(walkable(decl), depth + 1);
  }
}

// --- run -------------------------------------------------------------------------------
const sorted = (s: Set<string>) => [...s].sort();
let missing = 0;
const out = routes.map((r) => {
  if (!r.source) return r;
  const reg = findRegistration(r.source);
  if (!reg) {
    missing++;
    return { ...r, traced: false };
  }
  const fx = trace(reg);
  return {
    ...r,
    traced: true,
    tablesRead: sorted(fx.tablesRead).filter((t) => !fx.tablesWritten.has(t)),
    tablesWritten: sorted(fx.tablesWritten),
    websockets: sorted(fx.websockets),
    emails: sorted(fx.emails),
    storage: sorted(fx.storage),
    search: sorted(fx.search),
    jobs: sorted(fx.jobs),
    external: sorted(fx.external),
    entrypoints: sorted(fx.entrypoints),
    hooks: sorted(fx.hooks),
  };
});
writeFileSync(outPath, JSON.stringify(out, null, 2) + '\n');
// eslint-disable-next-line no-console
console.error(`traced ${out.length - missing} routes, ${missing} registrations not found, ` +
  `${tableByExport.size} tables, ${[...hooks.values()].flat().length} hook handlers`);
