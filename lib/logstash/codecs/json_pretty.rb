# encoding: utf-8
require "logstash/codecs/base"
require "json"
require "rbcat"

class JsonHighlighter
  def self.sort_hash(h)
    {}.tap do |h2|
      h.sort.each do |k,v|
        h2[k] = v.is_a?(Hash) ? sort_hash(v) : v
      end
    end
  end

  def self.highlight(object)
    # Fixed version of https://github.com/vifreefly/rbcat/blob/master/lib/rbcat/rules.rb
    rules = {
      value_integer: {
        regexp: /(?<=\"\:\s)\d+|(?<=\=\>\s)\d+/m,
        color: :blue
      },
      key_string: {
        regexp: /\"[^\"]*\"(?=\:)/m,
        color: :green
      },
      key_symbol: {
        regexp: /\:[\p{L}\_\d]*(?=\=\>)|\:\"[^\"]*\"(?=\=\>)/m,
        color: :magenta
      },
      value_string: {
        regexp: /\"(?:[^"\\]|\\.)*\"(?=[\,\n\}\]])|\"(?=[\,\n\}\]])/m,
        color: :yellow
      },
      value_null_nil: {
        regexp: /(?<=\:)null|(?<=\=\>)nil/m,
        color: :cyan
      },
      value_true_false: {
        regexp: /(?<=\:)(false|true)|(?<=\=\>)(false|true)/m,
        color: :cyan
      }
    }

    sorted_object = sort_hash(object)
    json_str = JSON.pretty_generate(sorted_object, { indent: '    ' })
    json_colorized = Rbcat.colorize(json_str, rules: rules)
    json_colorized
  end
end

class LogStash::Codecs::JsonPretty < LogStash::Codecs::Base
  config_name "json_pretty"

  # Should the event's metadata be included?
  config :metadata, :validate => :boolean, :default => false

  def register
    if @metadata
      @encoder = method(:encode_with_metadata)
    else
      @encoder = method(:encode_default)
    end
  end

  public
  def decode(data)
    raise "Not implemented"
  end # def decode

  public
  def encode(event)
    @encoder.call(event)
  end

  def encode_default(event)
    highlighted_json = JsonHighlighter.highlight(event.to_hash)
    @on_event.call(event, highlighted_json + NL)
  end

  def encode_with_metadata(event)
    highlighted_json = JsonHighlighter.highlight(event.to_hash_with_metadata)
    @on_event.call(event, highlighted_json + NL)
  end

end # class LogStash::Codecs::Dots

