require 'unit_spec_helper'

describe Shoulda::Matchers::ActiveModel::ValidationMessageFinder do
  context '#allow_description' do
    it 'describes its attribute' do
      finder = build_finder(attribute: :attr)

      description = finder.allow_description('allowed values')

      expect(description).to eq 'allow attr to be set to allowed values'
    end
  end

  context '#expected_message_from' do
    it 'returns the message as-is' do
      finder = build_finder

      message = finder.expected_message_from('some message')

      expect(message).to eq 'some message'
    end
  end

  context '#has_messages?' do
    it 'has messages when some validations fail' do
      finder = build_finder(format: /abc/, value: 'xyz')

      result = finder.has_messages?

      expect(result).to eq true
    end

    it 'has no messages when all validations pass' do
      finder = build_finder(format: /abc/, value: 'abc')

      result = finder.has_messages?

      expect(result).to eq false
    end
  end

  context '#messages' do
    it 'returns errors for the given attribute' do
      finder = build_finder(format: /abc/, value: 'xyz')

      messages = finder.messages

      expect(messages).to eq ['is invalid']
    end

    it 'returns an empty array if there are no errors for the given attribute' do
      finder = build_finder

      messages = finder.messages

      expect(messages).to eq([])
    end
  end

  context '#messages_description' do
    it 'describes errors for the given attribute' do
      finder = build_finder(
        attribute: :attr,
        format: /abc/,
        value: 'xyz'
      )

      description = finder.messages_description

      expect(description).to eq(
        %{ errors:\n* "is invalid" (attribute: attr, value: "xyz")}
      )
    end

    it 'describes errors when there are none' do
      finder = build_finder(format: /abc/, value: 'abc')

      description = finder.messages_description

      expect(description).to eq ' no errors'
    end

    it 'should not fetch attribute values for errors that were copied from an autosaved belongs_to association' do
      instance = define_model(:example) do
        validate do |record|
          record.errors.add('association.association_attribute', 'is invalid')
        end
      end.new
      finder = Shoulda::Matchers::ActiveModel::ValidationMessageFinder.new(instance, :attribute)

      expect(finder.messages_description).to eq(
        %{ errors:\n* "is invalid" (attribute: association.association_attribute)}
      )
    end

  end

  context '#source_description' do
    it 'describes the source of its messages' do
      finder = build_finder

      description = finder.source_description

      expect(description).to eq 'errors'
    end
  end

  def build_finder(arguments = {})
    arguments[:attribute] ||= :attr
    instance = build_instance_validating(
      arguments[:attribute],
      arguments[:format] || /abc/,
      arguments[:value] || 'abc'
    )
    Shoulda::Matchers::ActiveModel::ValidationMessageFinder.new(
      instance,
      arguments[:attribute]
    )
  end

  def build_instance_validating(attribute, format, value)
    model_class = define_model(:example, attribute => :string) do
      attr_accessible attribute
      validates_format_of attribute, with: format
    end

    model_class.new(attribute => value)
  end
end
