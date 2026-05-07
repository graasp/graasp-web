# Changelog

## [0.10.8](https://github.com/graasp/graasp-web/compare/v0.10.7...v0.10.8) (2026-05-07)


### Bug Fixes

* file upload issue on matching map ([8260b77](https://github.com/graasp/graasp-web/commit/8260b770a0c852800c74518493b330b500dd3461))

## [0.10.7](https://github.com/graasp/graasp-web/compare/v0.10.6...v0.10.7) (2026-05-06)


### Bug Fixes

* add item_memberships and thumbnails ([#249](https://github.com/graasp/graasp-web/issues/249)) ([054eb04](https://github.com/graasp/graasp-web/commit/054eb044a3310f34454aa45d57453eb08f821e48))
* add nudenet inference and orphan items ([#253](https://github.com/graasp/graasp-web/issues/253)) ([f263451](https://github.com/graasp/graasp-web/commit/f263451f4dd039222a6f3627fb2071c9cf189642))
* add tests ([#252](https://github.com/graasp/graasp-web/issues/252)) ([75b963c](https://github.com/graasp/graasp-web/commit/75b963cc4e5898fb7b662171df05bed1bfceb895))
* apply style changes ([#250](https://github.com/graasp/graasp-web/issues/250)) ([b2f235a](https://github.com/graasp/graasp-web/commit/b2f235a4f317be99dc5f312e026e8bd2f2e092f1))
* change scheduled cleanup time to account for daylight saving ([c175551](https://github.com/graasp/graasp-web/commit/c175551b125d097cab88295627bda8d8e410a604))
* remove usage of compile time var that gets copied ([#251](https://github.com/graasp/graasp-web/issues/251)) ([32e2b3d](https://github.com/graasp/graasp-web/commit/32e2b3dc97f79b16a3b7081c6168098b3d001ab9))
* style for about and contact page ([#254](https://github.com/graasp/graasp-web/issues/254)) ([3b2989d](https://github.com/graasp/graasp-web/commit/3b2989d2eda71e92976bd32dcb0008a65f211a8d))
* write release for 0.10.6 ([#247](https://github.com/graasp/graasp-web/issues/247)) ([995a8b8](https://github.com/graasp/graasp-web/commit/995a8b80f0b35137993376319dba76d97aa6a733))

## [0.10.6](https://github.com/graasp/graasp-web/compare/v0.10.5...v0.10.6) (2026-05-04)


### Bug Fixes

* add analytics path for react app ([#239](https://github.com/graasp/graasp-web/issues/239)) ([34b96db](https://github.com/graasp/graasp-web/commit/34b96dbc5471be4dcca963be8a72bfe534279959))
* add client build script ([#240](https://github.com/graasp/graasp-web/issues/240)) ([acaf45d](https://github.com/graasp/graasp-web/commit/acaf45d680d2c4524774bbaaa84e2ddf52a26814))
* add file cache for s3 urls ([#221](https://github.com/graasp/graasp-web/issues/221)) ([4030970](https://github.com/graasp/graasp-web/commit/4030970a579006838c0b1e10ecf33a341d3dde8f))
* add git hash to compiled env ([#241](https://github.com/graasp/graasp-web/issues/241)) ([7d66622](https://github.com/graasp/graasp-web/commit/7d6662218a544d5d9e3075a698c514d12a81da21))
* add indexes to improve perf when creating meilisearch data ([#244](https://github.com/graasp/graasp-web/issues/244)) ([02f0f05](https://github.com/graasp/graasp-web/commit/02f0f052200ff25a35358f4f9fd9fa78e64ce3d5))
* add japanese as a supported language ([#242](https://github.com/graasp/graasp-web/issues/242)) ([d0edb36](https://github.com/graasp/graasp-web/commit/d0edb365ed009464b68c1e829dd35b01d8b6e38b))
* add sentry test page ([#232](https://github.com/graasp/graasp-web/issues/232)) ([9d668eb](https://github.com/graasp/graasp-web/commit/9d668eb26d66657b592eb0d64f1d4efbc225b3ab))
* allow a large timeout for delete queries ([45a9d3a](https://github.com/graasp/graasp-web/commit/45a9d3ab1a9dbb9e4712f05aa8fec9f84a4360c3))
* improve code coverage ([#236](https://github.com/graasp/graasp-web/issues/236)) ([eb1de4e](https://github.com/graasp/graasp-web/commit/eb1de4e7cd2cd3982c523720223414a9886b4bca))
* improve trash page with job tracking and cancel button ([#235](https://github.com/graasp/graasp-web/issues/235)) ([a4e0b2f](https://github.com/graasp/graasp-web/commit/a4e0b2f410dab2718f45e81d52670140b4a72e24))
* **ja:** update translations ([#245](https://github.com/graasp/graasp-web/issues/245)) ([d8253e9](https://github.com/graasp/graasp-web/commit/d8253e94909e613c729238f96e0533c776da82f4))
* key is too long when emptying the trash ([#234](https://github.com/graasp/graasp-web/issues/234)) ([8477b08](https://github.com/graasp/graasp-web/commit/8477b08bb7caf54546b826a1706a28f78cd2f451))
* remove nil values from s3 config ([#238](https://github.com/graasp/graasp-web/issues/238)) ([f48e03d](https://github.com/graasp/graasp-web/commit/f48e03d856534b334ba92b255cd9af12ffe1d907))
* set application name on pg connection ([#237](https://github.com/graasp/graasp-web/issues/237)) ([7c9fada](https://github.com/graasp/graasp-web/commit/7c9fada913647ded826a498f43098becf97f6c6c))
* small issues and the test ([e8cf2a3](https://github.com/graasp/graasp-web/commit/e8cf2a31bf656722184795f8cdaa5861fcfcead3))
* update mise action version ([#246](https://github.com/graasp/graasp-web/issues/246)) ([5e75847](https://github.com/graasp/graasp-web/commit/5e7584789d2ed28c0051f4beb684a2079dac0eac))
* use batch delete for item tree deletion ([#243](https://github.com/graasp/graasp-web/issues/243)) ([8f28d34](https://github.com/graasp/graasp-web/commit/8f28d34cd1df2eb194a9dc1a68948ab36efc912c))

## [0.10.5](https://github.com/graasp/graasp-web/compare/v0.10.4...v0.10.5) (2026-04-20)


### Bug Fixes

* add about page for devs ([#226](https://github.com/graasp/graasp-web/issues/226)) ([6f1d8b9](https://github.com/graasp/graasp-web/commit/6f1d8b9753a7947b50a0ec1ebcec50af0478982e))
* add monitoring to menu ([#219](https://github.com/graasp/graasp-web/issues/219)) ([db5880e](https://github.com/graasp/graasp-web/commit/db5880e542e7cff69d76063d00436c99919e5b0f))


### Chores

* add logging of currenlty running version ([33022fc](https://github.com/graasp/graasp-web/commit/33022fc05478ed6247342620c3c69c1783c012ad))

## [0.10.4](https://github.com/graasp/graasp-web/compare/v0.10.0...v0.10.4) (2026-04-20)


### Features

* add recycled item background job ([#208](https://github.com/graasp/graasp-web/issues/208)) ([9f69a0d](https://github.com/graasp/graasp-web/commit/9f69a0d505020229c38bf3ff956bd6313fbb37cd))


### Bug Fixes

* accessibility issues detected on the landing page ([#214](https://github.com/graasp/graasp-web/issues/214)) ([d26a140](https://github.com/graasp/graasp-web/commit/d26a140e2882af7f3370d4b79ef398dfb8403b47))
* add health check with curl command in container ([91d572a](https://github.com/graasp/graasp-web/commit/91d572a1510828609e19f3236b4e6f8b88a37871))
* add index for h5p contentId query ([#217](https://github.com/graasp/graasp-web/issues/217)) ([c27967f](https://github.com/graasp/graasp-web/commit/c27967ff7cfefe7c06b0c2d2620e416d01f14249))
* add observability and metrics ([#216](https://github.com/graasp/graasp-web/issues/216)) ([b5645d2](https://github.com/graasp/graasp-web/commit/b5645d2f298229ca8a3b56a2ca1ae80cb9528cae))
* change order of preference for ExAws credentials ([3de36aa](https://github.com/graasp/graasp-web/commit/3de36aac28367e12fb95bb286793819f2855c04c))
* **ci:** update cluster name to restart the correct one depending on the environment ([#227](https://github.com/graasp/graasp-web/issues/227)) ([b60a044](https://github.com/graasp/graasp-web/commit/b60a0449971a007a3fcaf556e66b4468564fc1e2))
* overhaul the dashboard with live and new stats ([#215](https://github.com/graasp/graasp-web/issues/215)) ([8383db4](https://github.com/graasp/graasp-web/commit/8383db4e1dba56964c740cc1542ad8c4517ed090))
* update dependency bandit to 1.10.4 ([a84dd84](https://github.com/graasp/graasp-web/commit/a84dd8421969740bffafa0758806953904fb775c))
* update docs on backend setup ([#218](https://github.com/graasp/graasp-web/issues/218)) ([e0cc898](https://github.com/graasp/graasp-web/commit/e0cc8988b50ea0d5b294ea080bea3e332204cfdd))


### Chores

* **ci:** always restart service after deploy ([#212](https://github.com/graasp/graasp-web/issues/212)) ([d0834fc](https://github.com/graasp/graasp-web/commit/d0834fcf4e7836c0860783f0c20f7e3c84f23cf2))
* **deps:** update aws-actions/configure-aws-credentials action to v6 ([#211](https://github.com/graasp/graasp-web/issues/211)) ([4af0aa6](https://github.com/graasp/graasp-web/commit/4af0aa653d1853536bdd4fb2918cd57fcf8221ed))

## [0.10.0](https://github.com/graasp/graasp-web/compare/v0.9.4...v0.10.0) (2026-03-11)


### Features

* add developer docs ([#207](https://github.com/graasp/graasp-web/issues/207)) ([de35a45](https://github.com/graasp/graasp-web/commit/de35a457d5958533d97e4f2c51f45f407a4848f5))


### Bug Fixes

* use mise to setup ci tool versions ([#210](https://github.com/graasp/graasp-web/issues/210)) ([0245d03](https://github.com/graasp/graasp-web/commit/0245d03877b57e5a4c8fc0d42ac56664481746dc))


### Chores

* add blog post for v0.9.4 ([#206](https://github.com/graasp/graasp-web/issues/206)) ([537197d](https://github.com/graasp/graasp-web/commit/537197db9e95ac23c111a54fc419efdeded3ae48))

## [0.9.4](https://github.com/graasp/graasp-web/compare/v0.9.3...v0.9.4) (2026-03-09)


### Bug Fixes

* add a pre-connect directive for loading the font file ([#204](https://github.com/graasp/graasp-web/issues/204)) ([fa7091c](https://github.com/graasp/graasp-web/commit/fa7091c684d1e4a1e046c9ac05ee5e0d6ac83a49))
* add aria-label on link ([#202](https://github.com/graasp/graasp-web/issues/202)) ([65f4217](https://github.com/graasp/graasp-web/commit/65f42175b24acf94c87b0f57754a7f709288e5ee))
* **deps:** upgrade sentry ([818751e](https://github.com/graasp/graasp-web/commit/818751ecd4ce0625e19c8a07a5eabb6e2aa19a46))
* **de:** update translations ([#199](https://github.com/graasp/graasp-web/issues/199)) ([40756bb](https://github.com/graasp/graasp-web/commit/40756bb11d1f9b9af1342d2732d30efa2e9b2289))
* **fr:** update translations ([#200](https://github.com/graasp/graasp-web/issues/200)) ([45fbcff](https://github.com/graasp/graasp-web/commit/45fbcff5c4624f71a1c8f7157720760a8fb67393))
* lowercase docs ids ([#205](https://github.com/graasp/graasp-web/issues/205)) ([4e68e88](https://github.com/graasp/graasp-web/commit/4e68e881eec4df0429dbe79efabebf85cb3ea985))
* make cache improvements and feed improvements ([#203](https://github.com/graasp/graasp-web/issues/203)) ([04fc94e](https://github.com/graasp/graasp-web/commit/04fc94e76f7ac03a04e8f6f60966fa1a5dbe9616))

## [0.9.3](https://github.com/graasp/graasp-web/compare/v0.9.2...v0.9.3) (2026-03-05)


### Bug Fixes

* **es:** update translations ([#194](https://github.com/graasp/graasp-web/issues/194)) ([736f416](https://github.com/graasp/graasp-web/commit/736f416517fde190007a03b60b5dc756b634822a))
* **it:** update translations ([#195](https://github.com/graasp/graasp-web/issues/195)) ([f04e3a0](https://github.com/graasp/graasp-web/commit/f04e3a03c65b4c62a86c9b9d94daf3a0f14b8bc6))


### Chores

* update erlang version used in the ci ([#197](https://github.com/graasp/graasp-web/issues/197)) ([3cb20ec](https://github.com/graasp/graasp-web/commit/3cb20ec9015465345ad4518e0c1f9962f8584bef))

## [0.9.2](https://github.com/graasp/graasp-web/compare/v0.9.1...v0.9.2) (2026-03-04)


### Bug Fixes

* add atom feed ([#189](https://github.com/graasp/graasp-web/issues/189)) ([6dc014d](https://github.com/graasp/graasp-web/commit/6dc014d3434ece074519e107b08e3e60fca182ce))
* re-enable the register controller with the stub ([#191](https://github.com/graasp/graasp-web/issues/191)) ([4ac16c4](https://github.com/graasp/graasp-web/commit/4ac16c4e4d89b1fceb9e757049c79e38cfe917f7))

## [0.9.1](https://github.com/graasp/graasp-web/compare/v0.9.0...v0.9.1) (2026-03-03)


### Bug Fixes

* add a task to build from sibling directory ([c02e1f3](https://github.com/graasp/graasp-web/commit/c02e1f3bbebdec34761a9fa6a1aea5a62d8845b6))
* add client folder ([4f66a44](https://github.com/graasp/graasp-web/commit/4f66a44041ba833e6bf32a6acea6f6d21f2dd856))
* add paths for client app ([#164](https://github.com/graasp/graasp-web/issues/164)) ([919907d](https://github.com/graasp/graasp-web/commit/919907dfa55f18c319fe66828b7a7003ac8040f0))
* add the contact us message in the docs page ([#187](https://github.com/graasp/graasp-web/issues/187)) ([0697e97](https://github.com/graasp/graasp-web/commit/0697e97f4c179a0add168743072c746660aa303e))
* add umami website tracking ([#171](https://github.com/graasp/graasp-web/issues/171)) ([633b676](https://github.com/graasp/graasp-web/commit/633b6760020f0afed8e4f4e222aa6fbdc691eda4))
* adjust dark theme for better legibility ([#176](https://github.com/graasp/graasp-web/issues/176)) ([a7a6f09](https://github.com/graasp/graasp-web/commit/a7a6f0970242499daea491e59313bb9265bcb758))
* allow to set `graasp-review: enable` in localStorage with js from page footer ([#175](https://github.com/graasp/graasp-web/issues/175)) ([bcca350](https://github.com/graasp/graasp-web/commit/bcca350ed2c6bee408cc3188224b794963909573))
* **de:** update translations ([#179](https://github.com/graasp/graasp-web/issues/179)) ([999b0ed](https://github.com/graasp/graasp-web/commit/999b0ed4ef3f865dcc8136a6aa11da04d0fa4285))
* support link to go to docs ([#173](https://github.com/graasp/graasp-web/issues/173)) ([a36aca0](https://github.com/graasp/graasp-web/commit/a36aca09ccab6328a810bc7c57bdb5c0008a4dbe))
* typos in docs related to the account ([#186](https://github.com/graasp/graasp-web/issues/186)) ([37fc4ad](https://github.com/graasp/graasp-web/commit/37fc4ad40b05f3aad45c1c09693556cf800ef437))
* update elixir version and add flags via mise ([#188](https://github.com/graasp/graasp-web/issues/188)) ([a1f7a1b](https://github.com/graasp/graasp-web/commit/a1f7a1b7dcc89946254b2b7db6eb479305f99e26))
* update the copy command in the deploy workflow ([2608e69](https://github.com/graasp/graasp-web/commit/2608e69de82954cfd8992ed3c2290f8c31803390))


### Documentation

* add documentation about shortcuts ([#168](https://github.com/graasp/graasp-web/issues/168)) ([d041f35](https://github.com/graasp/graasp-web/commit/d041f35519bbcec009ac4f3c2b7f6e3125459e68))
* add new blog post for new prod release ([#177](https://github.com/graasp/graasp-web/issues/177)) ([baee098](https://github.com/graasp/graasp-web/commit/baee0987166af0766218d9091f2c752154067f80))
* fix shortcut behaviour description ([#178](https://github.com/graasp/graasp-web/issues/178)) ([5ab5336](https://github.com/graasp/graasp-web/commit/5ab5336c00cb5dfad9698d3dc55e34c53d25a164))


### Chores

* **deps:** update dependency bandit to v1.10.3 ([#184](https://github.com/graasp/graasp-web/issues/184)) ([d007783](https://github.com/graasp/graasp-web/commit/d007783044b490abd223e28d3c3d710b8ed37e20))
* remove artefacts from client ([57cb88b](https://github.com/graasp/graasp-web/commit/57cb88b491226d5b97d456f085bde2af25038125))
* update coverage ([#182](https://github.com/graasp/graasp-web/issues/182)) ([b9cf685](https://github.com/graasp/graasp-web/commit/b9cf685cd515bcd82e68121d85b13152f4bb2a7a))

## [0.9.0](https://github.com/graasp/admin/compare/v0.8.1...v0.9.0) (2026-02-24)


### Features

* add docs pages ([#163](https://github.com/graasp/admin/issues/163)) ([e2ee15b](https://github.com/graasp/admin/commit/e2ee15b63b3ad88b889991efd627bcf41cd67893))
* add unsubscribe ([#152](https://github.com/graasp/admin/issues/152)) ([714a975](https://github.com/graasp/admin/commit/714a975117c61e500dc46548de3a52510031d264))


### Bug Fixes

* update target id for js hiding of row in notification index ([#161](https://github.com/graasp/admin/issues/161)) ([e89eca0](https://github.com/graasp/admin/commit/e89eca0074244234c9ff4aef86fdd558b481ae3e))

## [0.8.1](https://github.com/graasp/admin/compare/v0.8.0...v0.8.1) (2026-02-06)


### Bug Fixes

* add error page ([#153](https://github.com/graasp/admin/issues/153)) ([91fbb64](https://github.com/graasp/admin/commit/91fbb640e2fc5609d0b4d4db3d26f3c013c1b763))
* add validation to account ([#160](https://github.com/graasp/admin/issues/160)) ([035e8e9](https://github.com/graasp/admin/commit/035e8e9ea21932ec11940d50bfb73bb523f5a9dc))
* improve coverage by adding missing tests ([#157](https://github.com/graasp/admin/issues/157)) ([47b574b](https://github.com/graasp/admin/commit/47b574b21d7dd314355afdbec56d470e3195e683))
* message length issues ([#156](https://github.com/graasp/admin/issues/156)) ([e4501b6](https://github.com/graasp/admin/commit/e4501b69277ec576bf1f402969adf271d7b25c76))

## [0.8.0](https://github.com/graasp/admin/compare/v0.7.0...v0.8.0) (2026-02-04)


### Features

* add static pages for terms, disclaimer and privacy ([#143](https://github.com/graasp/admin/issues/143)) ([cb3b20a](https://github.com/graasp/admin/commit/cb3b20a1b6ecd183a382c8663b8c0cb2479a0bb3))


### Bug Fixes

* add language form to blog pages to remove the crash ([#147](https://github.com/graasp/admin/issues/147)) ([e4f416a](https://github.com/graasp/admin/commit/e4f416a9c3c026c5a16157ebc4832e1b61519039))
* small fixups ([#151](https://github.com/graasp/admin/issues/151)) ([2617afb](https://github.com/graasp/admin/commit/2617afb912ab5e29a6e257650c0de5b4dbc60b2e))
* use standard graasp favicon for landing pages ([#148](https://github.com/graasp/admin/issues/148)) ([ab1cce1](https://github.com/graasp/admin/commit/ab1cce110a80d08f0db23d2ff72ab57485db1926))


### Chores

* **deps:** update dependency bandit to v1.10.2 ([#144](https://github.com/graasp/admin/issues/144)) ([68bdbab](https://github.com/graasp/admin/commit/68bdbab680f795fb35d16a9c53c68396756e63b5))
* **deps:** update dependency credo to v1.7.16 ([#145](https://github.com/graasp/admin/issues/145)) ([a2baf73](https://github.com/graasp/admin/commit/a2baf7337de6cadba50dab8334d89a5d55734e08))
* **lint:** udpate credo setting ([904b796](https://github.com/graasp/admin/commit/904b796c82d7a60adc3f5b8577ef0d1d84d38805))

## [0.7.0](https://github.com/graasp/admin/compare/v0.6.0...v0.7.0) (2026-01-29)


### Features

* add `About` and `Contact` page ([#136](https://github.com/graasp/admin/issues/136)) ([fa8946e](https://github.com/graasp/admin/commit/fa8946e8da7934185f66310bf57dbac46367cf82))
* add translations and locale to landing ([#140](https://github.com/graasp/admin/issues/140)) ([a951a89](https://github.com/graasp/admin/commit/a951a89227d749a200bd3062d82c3923f2e8778c))
* blog with nimble publisher ([#135](https://github.com/graasp/admin/issues/135)) ([d3fa230](https://github.com/graasp/admin/commit/d3fa2302288fccec661f062c124de74d1ca37492))


### Bug Fixes

* add sign-off to call to action email ([#137](https://github.com/graasp/admin/issues/137)) ([9569ccb](https://github.com/graasp/admin/commit/9569ccba0424e1597106a9f492f1503c218d9a82))
* addapt the colors ([d659e9f](https://github.com/graasp/admin/commit/d659e9f442cbfcf6432f50ae9823cd5774382d2d))
* define better theme colors ([#134](https://github.com/graasp/admin/issues/134)) ([6786834](https://github.com/graasp/admin/commit/67868347c4d15502922f6f3b1d6a93c015ec0fc6))
* re-organize admin home ([#139](https://github.com/graasp/admin/issues/139)) ([e780ced](https://github.com/graasp/admin/commit/e780ced569ce5afa387fe40f77838b699b53ea5b))
* set page titles ([#142](https://github.com/graasp/admin/issues/142)) ([21218aa](https://github.com/graasp/admin/commit/21218aa96bc87d3f050422e19ce84b1bf2ce5ce1))
* update daisyUI  ([#141](https://github.com/graasp/admin/issues/141)) ([0cbd29f](https://github.com/graasp/admin/commit/0cbd29f989a90223fe18664c2d0a5824b7af0faf))


### Chores

* upgrade otp to 28.1 ([196099f](https://github.com/graasp/admin/commit/196099f8b474aa7f514e6622420052b2f884d983))

## [0.6.0](https://github.com/graasp/admin/compare/v0.5.0...v0.6.0) (2026-01-21)


### Features

* add a page with reindex functionality ([#101](https://github.com/graasp/admin/issues/101)) ([a743e31](https://github.com/graasp/admin/commit/a743e31ea12b6df9bc340a50c4c287ec1db2e63f))
* add landing page ([#119](https://github.com/graasp/admin/issues/119)) ([f52d52d](https://github.com/graasp/admin/commit/f52d52d7b9792c8bf7e8a0a95ccfc5a68afe7cbc))
* add tracking pixels ([#128](https://github.com/graasp/admin/issues/128)) ([c771159](https://github.com/graasp/admin/commit/c7711599f7b7749292b82d9923e0f68787dbe0d7))


### Bug Fixes

* add english translations ([075ff00](https://github.com/graasp/admin/commit/075ff00a988ce49430a1782a5ef0a33e9ccb4f72))
* **de:** update translations ([#125](https://github.com/graasp/admin/issues/125)) ([e05af25](https://github.com/graasp/admin/commit/e05af2599d728d9ca98e3bf8e86cefdec00cbcd9))
* **es:** update translations ([#130](https://github.com/graasp/admin/issues/130)) ([eebc0d9](https://github.com/graasp/admin/commit/eebc0d9992fe0d7b49d27f59955797caedfbdfda))
* **fr:** update translations ([#122](https://github.com/graasp/admin/issues/122)) ([5925a65](https://github.com/graasp/admin/commit/5925a65e81bc6012d359eb3d874214112fb22f99))
* **it:** update translations ([#133](https://github.com/graasp/admin/issues/133)) ([4166636](https://github.com/graasp/admin/commit/4166636115cb4d526d9996759bfb79f76f0ebb0e))
* use `Graasp` as display name for noreply email ([#126](https://github.com/graasp/admin/issues/126)) ([4a2a70b](https://github.com/graasp/admin/commit/4a2a70bb16bde9fbda909c4c92ccdd4887efeab0))


### Chores

* add translation labels to readme ([c9e6397](https://github.com/graasp/admin/commit/c9e6397823853057e7f30a1c8b785972dce2c831))
* **mise:** use named arguments for `restart` task ([#120](https://github.com/graasp/admin/issues/120)) ([5ac7c60](https://github.com/graasp/admin/commit/5ac7c606fbb22585120d141681efa18733d55ffa))

## [0.5.0](https://github.com/graasp/admin/compare/v0.4.1...v0.5.0) (2026-01-13)


### Features

* add improved mailing ([#102](https://github.com/graasp/admin/issues/102)) ([5b6e0cc](https://github.com/graasp/admin/commit/5b6e0ccedc503382f3adeba6d92fad4206bc0457))
* setup `Gettext` for internationalisation in emails  ([#113](https://github.com/graasp/admin/issues/113)) ([b0450cd](https://github.com/graasp/admin/commit/b0450cdcc281dfa939917a30e1be2b7c69a282d2))
* single origin ([#106](https://github.com/graasp/admin/issues/106)) ([80213b8](https://github.com/graasp/admin/commit/80213b8d1467a416222bed4339e015b7d77a8924))


### Bug Fixes

* add an uptime command ([#115](https://github.com/graasp/admin/issues/115)) ([4695a3f](https://github.com/graasp/admin/commit/4695a3f5997e6f9f17e417a54e0b535412cf0957))
* credo ([5b6e0cc](https://github.com/graasp/admin/commit/5b6e0ccedc503382f3adeba6d92fad4206bc0457))
* do not send db event to sentry tracing ([#114](https://github.com/graasp/admin/issues/114)) ([1386a14](https://github.com/graasp/admin/commit/1386a14ef102e23f61d3268fb2f86b4550aa7317))
* improve mailing with localized langs ([5b6e0cc](https://github.com/graasp/admin/commit/5b6e0ccedc503382f3adeba6d92fad4206bc0457))
* make improvements ([5b6e0cc](https://github.com/graasp/admin/commit/5b6e0ccedc503382f3adeba6d92fad4206bc0457))
* make imrpovements ([5b6e0cc](https://github.com/graasp/admin/commit/5b6e0ccedc503382f3adeba6d92fad4206bc0457))
* make progress and have a working worker ([5b6e0cc](https://github.com/graasp/admin/commit/5b6e0ccedc503382f3adeba6d92fad4206bc0457))
* update views to use forms ([5b6e0cc](https://github.com/graasp/admin/commit/5b6e0ccedc503382f3adeba6d92fad4206bc0457))
* work in progress ([5b6e0cc](https://github.com/graasp/admin/commit/5b6e0ccedc503382f3adeba6d92fad4206bc0457))


### Chores

* update migrations and merge together to simplify ([#111](https://github.com/graasp/admin/issues/111)) ([8513ad8](https://github.com/graasp/admin/commit/8513ad8998a269e16b229ecbac3c2c066e637678))

## [0.4.1](https://github.com/graasp/admin/compare/v0.4.0...v0.4.1) (2026-01-05)


### Bug Fixes

* **ci:** add id-token permission for release please to aws OIDC ([e95bf0f](https://github.com/graasp/admin/commit/e95bf0fcf730938b15285b3472fca4d23bd8e480))

## [0.4.0](https://github.com/graasp/admin/compare/v0.3.0...v0.4.0) (2026-01-05)


### Features

* add admin name and lang ([#105](https://github.com/graasp/admin/issues/105)) ([3f6d491](https://github.com/graasp/admin/commit/3f6d491fde7d1dbcc8e65679ca6bfe6671ed45f8))


### Bug Fixes

* add task to restart containers ([9825700](https://github.com/graasp/admin/commit/98257000214ba7beb69f96e4c00372bfc9fa5742))
* improve readme ([#103](https://github.com/graasp/admin/issues/103)) ([a8f7b7f](https://github.com/graasp/admin/commit/a8f7b7fe1b79d1630f4ff7637cc3b0bdc54ad7ce))
* revert favicon to admin color ([1dc6ba1](https://github.com/graasp/admin/commit/1dc6ba1167cb28a6781557c6daeac0e9dc9f43bf))
* use redirect to navigate to the controller view ([#98](https://github.com/graasp/admin/issues/98)) ([e26bdc3](https://github.com/graasp/admin/commit/e26bdc383246a000195399b7e50ca5ef62d8b169))


### Chores

* **deps:** update dependency credo to v1.7.15 ([#107](https://github.com/graasp/admin/issues/107)) ([c0651d0](https://github.com/graasp/admin/commit/c0651d0ad7540fce3e626a22be914f3d82d355e9))
* **deps:** update dependency dialyxir to v1.4.7 ([#108](https://github.com/graasp/admin/issues/108)) ([eafa7b3](https://github.com/graasp/admin/commit/eafa7b3c2e1835f46f5038cd35dc59d4f4d34ebc))
* push a public image to ECR repository on release ([#109](https://github.com/graasp/admin/issues/109)) ([bc2629f](https://github.com/graasp/admin/commit/bc2629f904088aeb213cf5bfda773f7bfc5a060c))

## [0.3.0](https://github.com/graasp/admin/compare/v0.2.1...v0.3.0) (2025-12-09)


### Features

* POC using vega-lite ([#88](https://github.com/graasp/admin/issues/88)) ([4550e0a](https://github.com/graasp/admin/commit/4550e0adaff88851bf24f40a2eca91049d13f76d))


### Bug Fixes

* add "View details" button for publisher list ([#92](https://github.com/graasp/admin/issues/92)) ([600735a](https://github.com/graasp/admin/commit/600735a54179f312bc4a8d2b7fd7e506fdd229ef))
* allow to move app between compatible publishers ([#85](https://github.com/graasp/admin/issues/85)) ([dc82d5f](https://github.com/graasp/admin/commit/dc82d5f181890b4e3adb6c24f1a9a6a0e6dc8669))
* duplicate app name constraint ([#91](https://github.com/graasp/admin/issues/91)) ([7df9aae](https://github.com/graasp/admin/commit/7df9aae02fcf4b1daa3e963b23042bfed0429b5c))
* email region issue ([#81](https://github.com/graasp/admin/issues/81)) ([3bfe66a](https://github.com/graasp/admin/commit/3bfe66a68ded89433c2ac2d92c657cef63d0b277))
* publication thumbnail fallback ([#94](https://github.com/graasp/admin/issues/94)) ([08e5bbd](https://github.com/graasp/admin/commit/08e5bbd808c77b3e7e2b9866b847e55961b100a0))
* restrict the deployment concurrency to each env ([#84](https://github.com/graasp/admin/issues/84)) ([9ac3839](https://github.com/graasp/admin/commit/9ac38397f57efb70adc8943c7575d9f9ec1ed3d0))
* update admin users page and header ([#89](https://github.com/graasp/admin/issues/89)) ([2118089](https://github.com/graasp/admin/commit/2118089535215d3f99fef398c2628d03f383ae1d))
* update menu names ([#95](https://github.com/graasp/admin/issues/95)) ([2d33ae7](https://github.com/graasp/admin/commit/2d33ae7d105f9ebae703610f4aa58ce9c8bdd8ba))

## [0.2.1](https://github.com/graasp/admin/compare/v0.2.0...v0.2.1) (2025-12-03)


### Bug Fixes

* add s3 thumbnails for published_items ([#74](https://github.com/graasp/admin/issues/74)) ([5c4c634](https://github.com/graasp/admin/commit/5c4c634e45a80e24de94bbffdc61912f7f1020e5))
* display small thumbnails to their correct size ([ae65f75](https://github.com/graasp/admin/commit/ae65f752b71977be57228b50293567e8fc0e0d1b))
* improve emails with HTML ([#59](https://github.com/graasp/admin/issues/59)) ([b5f3eee](https://github.com/graasp/admin/commit/b5f3eeef64c1ffd144e244019761c705c991c9e5))
* published item search should use item_id ([#70](https://github.com/graasp/admin/issues/70)) ([fabf57d](https://github.com/graasp/admin/commit/fabf57dddf2cbeb6e3fc50f9b32a966691121788))
* send emails using ex_aws credentials ([#80](https://github.com/graasp/admin/issues/80)) ([7be1b9c](https://github.com/graasp/admin/commit/7be1b9cffcf669ba044cedb9b2a2323e5875a86f))
* set aws s3 region from env in runtime config ([#77](https://github.com/graasp/admin/issues/77)) ([40a8965](https://github.com/graasp/admin/commit/40a8965e09b2a1bbfc70f961ef6c10d6aa1ff245))
* upgrade elixir version to v1.19.4 ([#73](https://github.com/graasp/admin/issues/73)) ([a6f23e1](https://github.com/graasp/admin/commit/a6f23e19d002fabebe4a33c65b36f8581ae87366))
* use correct date comparisons ([#71](https://github.com/graasp/admin/issues/71)) ([82c3d34](https://github.com/graasp/admin/commit/82c3d34048f2882e0f9690e7c64caac42c1cda31))

## [0.2.0](https://github.com/graasp/admin/compare/v0.1.0...v0.2.0) (2025-11-27)


### Features

* add apps and publishers ([#11](https://github.com/graasp/admin/issues/11)) ([855ca0b](https://github.com/graasp/admin/commit/855ca0b69c9afa3fa7e4381a56144f9000e896d6))
* add auth via generators ([acf8a55](https://github.com/graasp/admin/commit/acf8a55da9895acfde4ff27b8524edec7cfcd654))
* add CI setup ([#20](https://github.com/graasp/admin/issues/20)) ([216d276](https://github.com/graasp/admin/commit/216d27624d33b7ae438a29b3991ddc4c33b47427))
* add jobs and mailing feature ([#48](https://github.com/graasp/admin/issues/48)) ([15c489c](https://github.com/graasp/admin/commit/15c489cb3a17ae1ae7488c08ca5a50e0fda2a1ac))
* landing page ([#42](https://github.com/graasp/admin/issues/42)) ([adf9ac4](https://github.com/graasp/admin/commit/adf9ac4ab8ffb8a8ef05c8adc5df18163e536e5d))
* planned maintenance ([#36](https://github.com/graasp/admin/issues/36)) ([9b5adb8](https://github.com/graasp/admin/commit/9b5adb834990df34f00ed2afa474dc70a6cfd09f))
* setup react app ([#38](https://github.com/graasp/admin/issues/38)) ([26cd1d5](https://github.com/graasp/admin/commit/26cd1d544fdaa1c6f2d541cc284404e79e572a8d))
* shared db ([#15](https://github.com/graasp/admin/issues/15)) ([8a3bf6b](https://github.com/graasp/admin/commit/8a3bf6bd1044657961ab7d47fe0014880d5f49fa))


### Bug Fixes

* add a limit to the recent publications list ([#25](https://github.com/graasp/admin/issues/25)) ([fb7383a](https://github.com/graasp/admin/commit/fb7383abc711876bb436f4d40e330eec0d774ae8))
* add AWS remote script ([#22](https://github.com/graasp/admin/issues/22)) ([02ad47d](https://github.com/graasp/admin/commit/02ad47da0c86a9b628638546f028a6ed9108be51))
* add deletion info in edit app page ([#32](https://github.com/graasp/admin/issues/32)) ([68a548b](https://github.com/graasp/admin/commit/68a548b345022145452e6681140f6eb850397069))
* add env in ci ([#21](https://github.com/graasp/admin/issues/21)) ([48b322a](https://github.com/graasp/admin/commit/48b322a915f03629f8e8758dc7ad113ba2c42a66))
* add mise scripts to remote and log into the task ([#31](https://github.com/graasp/admin/issues/31)) ([e5ad7ab](https://github.com/graasp/admin/commit/e5ad7ab930017e4cbe01fd01da0d0912e699dceb))
* add platform url helpers ([#62](https://github.com/graasp/admin/issues/62)) ([9013deb](https://github.com/graasp/admin/commit/9013deb1740a25d62c1ea1d2bcdd1e0b9e40b64e))
* add pnpm inside docker build image ([#41](https://github.com/graasp/admin/issues/41)) ([98c26ed](https://github.com/graasp/admin/commit/98c26ed5abf951d91f9ac1f845418b517318fd04))
* add release function to check migration status ([#49](https://github.com/graasp/admin/issues/49)) ([7e9b6df](https://github.com/graasp/admin/commit/7e9b6dfb2278e9c7cd6cfb8325d6679357b5a00b))
* add release please ([#45](https://github.com/graasp/admin/issues/45)) ([c693193](https://github.com/graasp/admin/commit/c6931936630c94528cfcf0fdb1f84fdb20624d78))
* add s3 controllers and configuration ([#35](https://github.com/graasp/admin/issues/35)) ([ad72ce5](https://github.com/graasp/admin/commit/ad72ce5c323c716a8f978087ce58820b39f0ff54))
* add sentry setup ([#10](https://github.com/graasp/admin/issues/10)) ([bf2979b](https://github.com/graasp/admin/commit/bf2979b8b7894a427520c245b60812d759f9993a))
* add ses region env var ([#24](https://github.com/graasp/admin/issues/24)) ([2324268](https://github.com/graasp/admin/commit/2324268f3e48168aa74bfc58ec6d5cb58b94279d))
* allow to rotate an app key ([#18](https://github.com/graasp/admin/issues/18)) ([26f7dce](https://github.com/graasp/admin/commit/26f7dcee227f0d0c1f34cddfedcda1bb801b4f5c))
* app publisher ordering ([#60](https://github.com/graasp/admin/issues/60)) ([82ccb9b](https://github.com/graasp/admin/commit/82ccb9b43a3e4f190b8834076bfa07e254a7ed66))
* apps ordering ([#61](https://github.com/graasp/admin/issues/61)) ([eca1892](https://github.com/graasp/admin/commit/eca1892fe944640b7e5ffeec622bb0dc0d5338c8))
* continue working on the publication form and search ([5f47d95](https://github.com/graasp/admin/commit/5f47d954bc9004137bcdd3711bfe7bb8f0bc24ca))
* dialog to confirm user deletion and user stats on dashboard ([5e701c8](https://github.com/graasp/admin/commit/5e701c8ade0bbc16ac9f0341213d470d86f9471b))
* docker can build frontend assets ([#44](https://github.com/graasp/admin/issues/44)) ([bd6e0b8](https://github.com/graasp/admin/commit/bd6e0b80dfc32707174750d2a43889a40342476b))
* improve publication display ([#63](https://github.com/graasp/admin/issues/63)) ([a69cdf2](https://github.com/graasp/admin/commit/a69cdf229e752b42ba3dac3faf89291d01e334a5))
* improve un-publish page ([#68](https://github.com/graasp/admin/issues/68)) ([e68f5e8](https://github.com/graasp/admin/commit/e68f5e84b3fc9332a5500a1eeb8eb885987f7233))
* improve validation of apps and display of errors ([#66](https://github.com/graasp/admin/issues/66)) ([d3def42](https://github.com/graasp/admin/commit/d3def42a60d29096f67d8844e37f891b021cae46))
* installation docs ([c939729](https://github.com/graasp/admin/commit/c9397299dbd310810ce3809920e9d80dd8530f64))
* make changes requested after demo ([599805e](https://github.com/graasp/admin/commit/599805eab3502d6d18c04641c6d259316db52fb6))
* make requested changes for apps and publisher ([ff90b44](https://github.com/graasp/admin/commit/ff90b445d90192e21d489de9347460400c6bcef0))
* path change in app ([#43](https://github.com/graasp/admin/issues/43)) ([2105967](https://github.com/graasp/admin/commit/2105967680cb4d63f27ae4558e047dd5a43a499a))
* remove kamal configs and hide docs related to it ([#16](https://github.com/graasp/admin/issues/16)) ([45329e0](https://github.com/graasp/admin/commit/45329e0e5c80b6093cfd1cd02b1cf091595021ad))
* rename users table to admins ([#19](https://github.com/graasp/admin/issues/19)) ([4d5dc3f](https://github.com/graasp/admin/commit/4d5dc3f066e8de6b2f3e46865c577632355a910b))
* restart service after deploy and disable concurrency ([#23](https://github.com/graasp/admin/issues/23)) ([19bfc8a](https://github.com/graasp/admin/commit/19bfc8adc0ccb126e078adbf9bf94edb8ac43669))
* setup credo to perform static code analysis with dialyzer ([#28](https://github.com/graasp/admin/issues/28)) ([21fa759](https://github.com/graasp/admin/commit/21fa7591f2187f63abb0f2689183784294dfccb6))
* setup docs ([11d55c9](https://github.com/graasp/admin/commit/11d55c9779a66450ad2ac41fa89a70d523914481))
* tests ([8b6e202](https://github.com/graasp/admin/commit/8b6e202b3fbb159f77a37a4e86036a51f5310ce3))
* update for shared database ([940ef57](https://github.com/graasp/admin/commit/940ef57f95d8f02f54a594b4f39f5caa4c0cdc66))
* update header for smaller screens sizes ([#26](https://github.com/graasp/admin/issues/26)) ([5af535d](https://github.com/graasp/admin/commit/5af535d1590c8f2cb3cb70a555a69c0e792dcb4a))
* update log validation ([#52](https://github.com/graasp/admin/issues/52)) ([9a478de](https://github.com/graasp/admin/commit/9a478de19106646b6685937053e01d40a714c661))
* update navigation bars and content ([9c54e7f](https://github.com/graasp/admin/commit/9c54e7fa7595c344745ad8ee88438aabf51afd65))
* update readme ([0500789](https://github.com/graasp/admin/commit/05007899bc9c6f6b81807b90e1e8b03d031dd5d9))
* update sentry configuration ([#39](https://github.com/graasp/admin/issues/39)) ([9c815ec](https://github.com/graasp/admin/commit/9c815ec6ef8802b062913b5436a0c76de1c56ce4))
* update tailwind in lockfile ([#40](https://github.com/graasp/admin/issues/40)) ([0ce1872](https://github.com/graasp/admin/commit/0ce1872dd455146952d2d8e7f4b5d6c2539b6ed3))
* update tests for new features ([cc37539](https://github.com/graasp/admin/commit/cc37539e7b8e753ce1272721c13429c370071845))
* upgrade deps ([#37](https://github.com/graasp/admin/issues/37)) ([008aeca](https://github.com/graasp/admin/commit/008aecaae425c91cf0fc7e960dfbf325f5cb096e))
* use better input type for maintenance form ([#67](https://github.com/graasp/admin/issues/67)) ([1e95066](https://github.com/graasp/admin/commit/1e95066c7355ba6f1c506ccfe355e6afae8b9e36))
* use created_at instead of inserted_at ([bdb0547](https://github.com/graasp/admin/commit/bdb0547df1477726ac371d09d352090d302af95c))
* use uuid as primary key ([5bae3d1](https://github.com/graasp/admin/commit/5bae3d125d54d61f5b8df446822b3ee34ae5f37b))


### Chores

* initial commit ([32de7a6](https://github.com/graasp/admin/commit/32de7a6ecfb4818bc2341f097ced23e162013507))
* remove react frontend ([3a0cbf1](https://github.com/graasp/admin/commit/3a0cbf1e55967eae02dadf56e0e0f7e7c1268519))
* update dependencies ([0f85bb3](https://github.com/graasp/admin/commit/0f85bb3c9aec24fefd2ba2faac747c946b95ad35))
