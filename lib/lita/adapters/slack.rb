require 'lita'
require 'faraday'
require 'json'

module Lita
  module Adapters
    class Slack < Adapter
      # Required Lita config keys (via lita_config.rb)
      require_configs :incoming_token, :team_domain

      # Adapter main run loop
      def run
        listen_to_sqs
        log.debug 'Slack::run started'
        sleep
      rescue Interrupt
        shut_down
      end

      def send_messages(target, strings)
        log.debug 'Slack::send_messages started'
        status = http_post prepare_payload(target, strings)
        log.error "Slack::send_messages failed to send (#{status})" if status != 200
        log.debug 'Slack::send_messages ending'
      end

      def set_topic(target, topic)
        # Slack currently provides no method
        log.info 'Slack::set_topic no implementation'
      end

      def shut_down
      end

      private

      def listen_to_sqs
        return unless config.sqs_queue_name
        require 'lita/adapters/slack/sqs_subscriber'
        SqsSubscriber.listen(robot)
        log.debug 'Listening to SQS messages'
      end

      def prepare_payload(target, strings)
        if not defined?(target.room)
          channel_id = nil
          log.warn "Slack::prepare_payload proceeding without channel designation"
        else
          channel_id = target.room
        end
        payload = {'channel' => channel_id, 'username' => username}
        payload['text'] = strings.join('\n')
        if add_mention? and defined?(target.user.id)
          payload['text'] = payload['text'].prepend("<@#{target.user.id}> ")
        end
        payload
      end

      def http_post(payload)
        res = Faraday.post do |req|
          log.debug "Slack::http_post sending payload to #{incoming_url}; length: #{payload.to_json.size}"
          req.url incoming_url, :token => config.incoming_token
          req.headers['Content-Type'] = 'application/json'
          req.body = payload.to_json
        end
        log.info "Slack::http_post sent payload with response status #{res.status}"
        log.debug "Slack::http_post response body: #{res.body}"
        res.status
      end

      #
      # Accessor shortcuts
      #
      def config
        Lita.config.adapter
      end

      def log
        Lita.logger
      end

      def incoming_url
        config.incoming_url ||
          "https://#{config.team_domain}.slack.com/services/hooks/incoming-webhook"
      end

      def username
        config.username
      end

      def add_mention?
        config.add_mention
      end
    end

    # Register Slack adapter to Lita
    Lita.register_adapter(:slack, Slack)
  end
end
