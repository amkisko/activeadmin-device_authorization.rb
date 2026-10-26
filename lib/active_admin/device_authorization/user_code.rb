# frozen_string_literal: true

module ActiveAdmin
  module DeviceAuthorization
    module UserCode
      MAX_GENERATION_ATTEMPTS = 100
      class GenerationExhausted < StandardError; end

      module_function

      def generate(config: ActiveAdmin::DeviceAuthorization.config, exists: nil)
        alphabet = Array(config.user_code_alphabet)
        raise ArgumentError, "user_code_alphabet must not be empty" if alphabet.empty?

        count = config.user_code_character_count.to_i
        group = config.user_code_group_size.to_i
        raise ArgumentError, "user_code_character_count must be positive" if count <= 0

        MAX_GENERATION_ATTEMPTS.times do
          chars = Array.new(count) { alphabet[SecureRandom.random_number(alphabet.size)] }
          code =
            if group.positive?
              chars.each_slice(group).map(&:join).join("-")
            else
              chars.join
            end
          return code if exists.nil? || !exists.call(code)
        end

        raise GenerationExhausted, "could not allocate a unique user code"
      end

      def normalize(value, config: ActiveAdmin::DeviceAuthorization.config)
        raw = value.to_s.strip.upcase
        alphabet = Array(config.user_code_alphabet).each_with_object({}) do |character, canonical|
          canonical[character.to_s.upcase] = character.to_s
        end
        characters = raw.each_char.filter_map { |character| alphabet[character.upcase] }
        return raw unless characters.length == config.user_code_character_count.to_i

        group = config.user_code_group_size.to_i
        return characters.join unless group.positive?

        characters.each_slice(group).map(&:join).join("-")
      end
    end
  end
end
