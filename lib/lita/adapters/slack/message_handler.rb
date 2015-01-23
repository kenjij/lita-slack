module Lita
  module Adapters
    class Slack < Adapter
      class MessageHandler
        def initialize(robot, robot_id, data, channel_mapping)
          @robot = robot
          @robot_id = robot_id
          @data = data
          @type = data["type"]
          @channel_mapping = channel_mapping
        end

        def handle
          case type
          when "hello"
            handle_hello
          when "message"
            handle_message
          when "user_change", "team_join"
            handle_user_change
          when "bot_added", "bot_changed"
            handle_bot_change
          when "error"
            handle_error
          else
            handle_unknown
          end
        end

        private

        attr_reader :data
        attr_reader :robot
        attr_reader :robot_id
        attr_reader :type

        def body
          data["text"].to_s
            .sub(/^\s*<@#{robot_id}>/, "@#{robot.mention_name}")
            .gsub(/&lt;/, '<')
            .gsub(/&gt;/, '>')
            .gsub(/&amp;/, '&')
            .gsub(/<(?<type>[@#!])?(?<link>[^>|]+)(?:\|(?<label>[^>]+))?>/i) do
              link = Regexp.last_match[:link]
              label = Regexp.last_match[:label]
              case Regexp.last_match[:type]
                when '@'
                  if label
                    label
                  else
                    user = User.find_by_id link
                    if user
                      "@#{user.name}"
                    else
                      "@#{link}"
                    end
                  end
                when '#'
                  if label
                    label
                  else
                    channel = @channel_mapping.channel_for link
                    if channel
                      "\##{channel}"
                    else
                      "\##{link}"
                    end
                  end
                when '!'
                  "@#{link}"  if ['channel','group','everyone'].include? link
                else
                  link = link.gsub /^mailto:/, ''
                  if label and not link.include? label
                    "#{label} (#{link})"
                  else
                    link
                  end
              end
            end
        end

        def channel
          data["channel"]
        end

        def dispatch_message(user)
          source = Source.new(user: user, room: channel)
          message = Message.new(robot, body, source)
          log.debug("Dispatching message to Lita from #{user.id}.")
          robot.receive(message)
        end

        def from_self?(user)
          if data["subtype"] == "bot_message"
            robot_user = User.find_by_name(robot.name)

            robot_user && robot_user.id == user.id
          end
        end

        def handle_bot_change
          log.debug("Updating user data for bot.")
          UserCreator.create_user(SlackUser.from_data(data["bot"]), robot, robot_id)
        end

        def handle_error
          error = data["error"]
          code = error["code"]
          message = error["msg"]
          log.error("Error with code #{code} received from Slack: #{message}")
        end

        def handle_hello
          log.info("Connected to Slack.")
          robot.trigger(:connected)
        end

        def handle_message
          return unless supported_subtype?

          user = User.find_by_id(data["user"]) || User.create(data["user"])

          return if from_self?(user)

          dispatch_message(user)
        end

        def handle_unknown
          unless data["reply_to"]
            log.debug("#{type} event received from Slack and will be ignored.")
          end
        end

        def handle_user_change
          log.debug("Updating user data.")
          UserCreator.create_user(SlackUser.from_data(data["user"]), robot, robot_id)
        end

        def log
          Lita.logger
        end

        # Types of messages Lita should dispatch to handlers.
        def supported_message_subtypes
          %w(bot_message me_message)
        end

        def supported_subtype?
          subtype = data["subtype"]

          if subtype
            supported_message_subtypes.include?(subtype)
          else
            true
          end
        end
      end
    end
  end
end
