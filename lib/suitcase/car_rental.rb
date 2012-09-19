module Suitcase
  class CarRental
    attr_accessor :seating, :type_name, :type_code, :possible_features, :possible_models, :deep_link, :total_price, :daily_rate

    def initialize(data)
      @deep_link = data["DeepLink"]
      @total_price = data["TotalPrice"]
      @daily_rate = data["DailyRate"]
      @seating = data["CarTypeSeating"]
      @type_name = data["CarTypeName"]
      @type_code = data["CarTypeCode"]
      @possible_features = data["PossibleFeatures"]
      @possible_models = data["PossibleModels"].split(', ') if data["PossibleModels"]
    end

    class << self
      
      def find(info)
        parsed = parse_json(build_url(info))
        parse_errors(parsed)
        car_types = parsed["MetaData"]["CarMetaData"]["CarTypes"]
        
        parsed["Result"].map do |data|
          car_type = car_types.select{|c| c["CarTypeCode"] == data["CarTypeCode"]}.first
          data["PossibleModels"] = car_type["PossibleModels"]
          data["PossibleFeatures"] = car_type["PossibleFeatures"]
          data["CarTypeName"] = car_type["CarTypeName"]
          CarRental.new(data)
        end
      end

      def build_url(info)
        base_url = "http://api.hotwire.com/v1/search/car"
        info["apikey"] = Configuration.hotwire_api_key
        info["format"] = "JSON"
        if Configuration.use_hotwire_linkshare_id?
          info["linkshareid"] = Configuration.hotwire_linkshare_id
        end
        info["dest"] = info.delete(:destination)
        info["startdate"] = info.delete(:start_date)
        info["enddate"] = info.delete(:end_date)
        info["pickuptime"] = info.delete(:pickup_time)
        info["dropofftime"] = info.delete(:dropoff_time)
        base_url += "?" + parameterize(info)

        URI.parse(URI.escape(base_url))
      end

      def parameterize(info)
        info.map { |key, value| "#{key}=#{value}" }.join("&")
      end

      def parse_json(uri)
        response = Net::HTTP.get_response(uri)
        raise "Data not valid." if response.code != "200"
        JSON.parse(response.body)
      end

      def parse_errors(parsed)
        if parsed["Errors"] && !parsed["Errors"].empty?
          parsed["Errors"].each { |e| raise e }
        end
      end
    end
  end
end
