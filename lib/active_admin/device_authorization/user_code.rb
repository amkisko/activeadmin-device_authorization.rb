# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    module UserCode
      module_function

      def generate(config: ActiveAdmin::DeviceAuthorization.config, exists: nil)
        alphabet = Array(config.user_code_alphabet)
        raise ArgumentError, "user_code_alphabet must not be empty" if alphabet.empty?

        count = config.user_code_character_count.to_i
        group = config.user_code_group_size.to_i
        raise ArgumentError, "user_code_character_count must be positive" if count <= 0

        loop do
          chars = Array.new(count) { alphabet[SecureRandom.random_number(alphabet.size)] }
          code =
            if group.positive?
              chars.each_slice(group).map(&:join).join("-")
            else
              chars.join
            end
          break code if exists.nil? || !exists.call(code)
        end
      end
    end
  end
end
