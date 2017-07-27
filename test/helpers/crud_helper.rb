module CRUDHelper
  def model_name
    model.to_s.downcase
  end

  def model_sym
    model_name.to_sym
  end

  def model_params(attrs)
    {
      model_sym => attrs
    }
  end

  # Generates a hash which maps attribute names on valid
  # attribute values using the model's factory.
  def generate_attr_hash
    instance = build(model_sym)
    Hash[allowed_attrs.map { |attr| [attr, instance.send(attr)] }]
  end

  # Generates attributes from the model factory, then checks whether
  # given block produces an object that has these attributes set.
  def assert_produces_object_with_attributes
    attrs = generate_attr_hash
    obj = yield attrs
    check_attrs(attrs, obj)
  end

  # Checks wether the attributes of the given object are equal
  # to the values of the given attr_hash
  def check_attrs(attr_hash, obj)
    not_equal = []
    attr_hash.each do |attr_name, value|
      actual = obj.send(attr_name)
      next if value == actual
      not_equal << <<~MSG
        Attribute #{attr_name}
          Expected: \"#{value}\"
          Actual:   \"#{actual}"
      MSG
    end
    assert not_equal.empty?,
           <<~MSG
             The following attributtes are not equal:
             #{not_equal.join "\n"}
           MSG
  end

  # Read (show, index, new, edit)

  def should_show
    get polymorphic_url(@instance)
    assert_response :success
  end

  def should_get_index
    get polymorphic_url(model)
    assert_response :success
  end

  def should_get_new
    get new_polymorphic_url(model)
    assert_response :success
  end

  def should_get_edit
    get edit_polymorphic_url(@instance)
    assert_response :success
  end

  # Create

  # Creates a new model (optionally with the given attributes,
  # otherwise the attributes are generated) and assert that model.count
  # is increased by one.
  def create_request_expect(attr_hash: nil)
    assert_difference("#{model}.count", +1, "#{model} was not created") do
      create_request attr_hash: attr_hash
    end
    model.order(:id).last
  end

  # Creates a new model (optionally with the given attributes
  # otherwise the attributes are generated).
  def create_request(attr_hash: nil)
    attr_hash ||= generate_attr_hash
    post polymorphic_url(model), params: model_params(attr_hash)
  end

  def should_set_attributes_on_create
    assert_produces_object_with_attributes do |attr_hash|
      create_request_expect attr_hash: attr_hash
    end
  end

  def should_redirect_on_create
    create_request_expect
    assert_redirected_to polymorphic_url(model.last)
  end

  # Update

  def update_request(attr_hash: nil)
    attr_hash ||= generate_attr_hash
    patch polymorphic_url(@instance), params: model_params(attr_hash)
    @instance.reload
  end

  def should_set_attributes_on_update
    assert_produces_object_with_attributes do |attr_hash|
      update_request attr_hash: attr_hash
    end
  end

  def should_redirect_on_update
    update_request
    assert_redirected_to polymorphic_url(@instance)
  end

  # Destroy

  def destroy_request
    delete polymorphic_url(@instance)
  end

  def should_destroy
    assert_difference("#{model}.count", -1) do
      destroy_request
    end
  end

  def should_redirect_on_destroy
    destroy_request
    assert_redirected_to polymorphic_url(model)
  end
end

module CRUDTest
  # Tests crud (create, read, update, delete) methods for rails controllers.
  def test_crud_actions(model, options = {})
    model_name = model.to_s.downcase

    attrs = options[:attrs] || {}

    actions = options[:only] || %i[index new create show edit update destroy]

    subactions = []
    actions.each do |action|
      case action
      when :create
        subactions << :create_redirect
      when :update
        subactions << :update_redirect
      when :destroy
        subactions << :destroy_redirect
      end
    end
    actions += subactions

    except = options[:except] || []
    actions -= except

    include(CRUDHelper)

    define_method(:model) do
      model
    end

    define_method(:allowed_attrs) do
      attrs
    end

    # This hash maps the action symbol on an array
    # which has the test message as first item and a lambda with what to
    # test as the second item.
    # == Example:
    #  index:
    #    ["should get #{model_name} index",
    #     -> { should_get_index }],
    #
    # # Is equivalent to
    #
    # if actions.include?(:index) do
    #   test "should get #{model_name} index" do
    #     should_get_index
    #   end
    # end
    #
    action_hash = {
      index:
        ["should get #{model_name} index",
         -> { should_get_index }],
      new:
        ["should get new #{model_name}",
         -> { should_get_new }],
      create:
        ["create #{model_name} should set attributes",
         -> { should_set_attributes_on_create }],
      create_redirect:
        ["create #{model_name} should redirect",
         -> { should_redirect_on_create }],
      show:
        ["should show #{model_name}",
         -> { should_show }],
      edit:
        ["should get edit #{model_name}",
         -> { should_get_edit }],
      update:
        ["update #{model_name} should set attributes",
         -> { should_set_attributes_on_update }],
      update_redirect:
        ["update #{model_name} should redirect",
         -> { should_redirect_on_update }],
      destroy:
        ["should destroy #{model_name}",
         -> { should_destroy }],
      destroy_redirect:
        ["destroy #{model_name} should redirect",
         -> { should_redirect_on_destroy }]
    }

    # Actually map actions on the tests
    actions.each do |action|
      msg, fun = action_hash[action]
      test(msg, &fun)
    end
  end
end
