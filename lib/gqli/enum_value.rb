# frozen_string_literal: true

module GQLi
  # Wrapper for Enum values
  class EnumValue
    attr_reader :value

    def initialize(value)
      @value = value
    end

    # Serializes the enum value to string
    def to_s
      value.to_s
    end
  end
end
