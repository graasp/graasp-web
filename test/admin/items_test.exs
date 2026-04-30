defmodule Admin.ItemsTest do
  use Admin.DataCase, async: true

  alias Admin.Items

  alias Admin.Items.Item

  import Admin.AccountsFixtures, only: [user_scope_fixture: 0]
  import Admin.ItemsFixtures

  describe "item" do
    @invalid_attrs %{extra: nil, name: nil, type: nil, path: nil, description: nil, settings: nil}

    test "list_item/1 returns all item" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      item = item_fixture(scope)
      other_item = item_fixture(other_scope)
      assert Items.list_item(scope) == [item, other_item]
    end

    test "get_item!/2 returns the item with given id" do
      scope = user_scope_fixture()
      item = item_fixture(scope)
      assert Items.get_item!(scope, item.id) == item
    end

    test "create_item/2 with valid data creates a item" do
      valid_attrs = %{
        extra: %{},
        name: "some name",
        type: "some type",
        path: "1234.5678",
        description: "some description",
        settings: %{},
        creator_id: Ecto.UUID.generate()
      }

      scope = user_scope_fixture()

      assert {:ok, %Item{} = item} = Items.create_item(scope, valid_attrs)
      assert item.extra == %{}
      assert item.name == "some name"
      assert item.type == "some type"
      assert item.path == %EctoLtree.LabelTree{labels: ["1234", "5678"]}
      assert item.description == "some description"
      assert item.settings == %{}
    end

    test "create_item/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Items.create_item(scope, @invalid_attrs)
    end

    test "update_item/3 with valid data updates the item" do
      scope = user_scope_fixture()
      item = item_fixture(scope)

      update_attrs = %{
        extra: %{},
        name: "some updated name",
        type: "some updated type",
        path: "1234.5678.9012",
        description: "some updated description",
        settings: %{}
      }

      assert {:ok, %Item{} = item} = Items.update_item(scope, item, update_attrs)
      assert item.extra == %{}
      assert item.name == "some updated name"
      assert item.type == "some updated type"
      assert item.path == %EctoLtree.LabelTree{labels: ["1234", "5678", "9012"]}
      assert item.description == "some updated description"
      assert item.settings == %{}
    end

    test "update_item/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      item = item_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Items.update_item(scope, item, @invalid_attrs)
      assert item == Items.get_item!(scope, item.id)
    end

    test "delete_item/2 deletes the item" do
      scope = user_scope_fixture()
      item = item_fixture(scope)
      assert {:ok, %Item{}} = Items.delete_item(scope, item)
      assert_raise Ecto.NoResultsError, fn -> Items.get_item!(scope, item.id) end
    end

    test "change_item/2 returns a item changeset" do
      scope = user_scope_fixture()
      item = item_fixture(scope)
      assert %Ecto.Changeset{} = Items.change_item(scope, item)
    end
  end

  test "get_descendants/1 for lone item returns itself" do
    scope = user_scope_fixture()
    item = item_fixture(scope)
    descendants = Items.get_descendants(item.path)
    assert descendants == [item]
  end

  describe "descendants" do
    test "get_descendants/1 for item with children returns all descendants" do
      scope = user_scope_fixture()

      tree_structure = [
        {%{name: "parent"},
         [
           {%{name: "child"},
            [
              {%{name: "grandchild"}, []}
            ]},
           {%{name: "child_2"}, []}
         ]},
        {%{name: "parent_2"}, []}
      ]

      [{parent, [{child, [{grandchild, []}]}, {child_2, []}]}, {_parent_2, []}] =
        build_tree(scope, tree_structure)

      descendants = Items.get_descendants(parent.path)
      assert descendants == [parent, child, child_2, grandchild]

      descendants_of_child = Items.get_descendants(child.path)
      assert descendants_of_child == [child, grandchild]
    end
  end

  describe "delete tree" do
    test "deletes a tree and all descendants" do
      scope = user_scope_fixture()

      tree_structure = [
        {%{name: "parent_1"},
         [
           {%{name: "child_1"}, []},
           {%{name: "child_2"}, []}
         ]},
        {%{name: "parent_2"}, []}
      ]

      [{parent_1, _}, {parent_2, []}] =
        build_tree(scope, tree_structure)

      assert {3, nil} = Items.delete_tree(parent_1.path)
      descendants = Items.get_descendants(parent_1.path)
      assert descendants == []
      assert [parent_2] == Items.get_descendants(parent_2.path)
    end
  end

  describe "get_by_h5p_content_id/1" do
    test "returns the item with the given h5p content id" do
      scope = user_scope_fixture()
      content_id = Ecto.UUID.generate()
      item = item_fixture(scope, %{type: "h5p", extra: %{"h5p" => %{"contentId" => content_id}}})

      assert item.id == Items.get_by_h5p_content_id(content_id)
    end

    test "returns nil when no item has the given h5p content id" do
      content_id = Ecto.UUID.generate()
      assert nil == Items.get_by_h5p_content_id(content_id)
    end
  end

  describe "build_tree/1" do
    test "builds a tree from a list of tree structures" do
      scope = user_scope_fixture()

      tree_structure = [
        {%{name: "parent_1"},
         [
           {%{name: "child_1"}, []},
           {%{name: "child_2"}, []}
         ]},
        {%{name: "parent_2"}, []}
      ]

      [{parent_1, [{child_1, []}, {child_2, []}]}, {parent_2, []}] =
        build_tree(scope, tree_structure)

      assert "parent_1" == parent_1.name
      assert "child_1" == child_1.name
      assert "child_2" == child_2.name
      assert "parent_2" == parent_2.name

      # assert child contains path of parent
      assert Items.PathUtils.to_string(child_1.path) =~
               Items.PathUtils.to_string(parent_1.path)
    end
  end
end
