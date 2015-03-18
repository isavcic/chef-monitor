#
# Nagios performance data to Graphite plain text mutator extension.
# ===
#
# Copyright 2013 Heavy Water Operations, LLC.
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

module Sensu
  module Extension
    class NagiosPerfData < Mutator
      def name
        'nagios_perfdata'
      end

      def description
        'converts nagios performance data to graphite plain text'
      end

      def run(event)
        result = []
        client = event[:client]
        check  = event[:check]

        # I can has perfdata?
        if check[:output].include? '|'
          # https://www.nagios-plugins.org/doc/guidelines.html#AEN200
          perfdata = check[:output].split('|').last.strip

          perfdata.split(/\s+/).each do |data|
            # label=value[UOM];[warn];[crit];[min];[max]
            label, value = data.split('=')

            # Removing leading, trailing and multiple underlines
            name = label.strip.gsub(/\W/, '_').gsub(/^_+/, '').gsub(/_+$/, '').gsub(/_+/, '_')
            measurement = value.strip.split(';').first.gsub(/[^-\d\.]/, '')

            # We don't want dots in client name
            path = [client[:name].gsub('.', '-'), check[:name], name].join('.')

            result << [path, measurement, check[:executed]].join("\t")
          end
          yield(result.join("\n") + "\n", 0)
        else
          # No perfdata, bailing out
          yield("\n", 0)
        end
      end
    end
  end
end
