class Serializer {
    int blockLevel;

    function init(int blockLevel = 1) {
        self.blockLevel = blockLevel;
    }

    function serialize(json data, int depthLevel = 0) returns Event[]|SerializingError {
        Event[] events = [];
        // TODO: check if the data is a custom tag

        // TODO: check if the current schema is CORE_SCHEMA

        // TODO: check if the current schema is JSON_SCHEMA

        // Convert sequence
        if data is json[] {
            events.push({startType: SEQUENCE, flowStyle: self.blockLevel <= depthLevel});

            foreach json dataItem in data {
                events = self.combineArray(events, check self.serialize(dataItem, depthLevel + 1));
            }

            events.push({endType: SEQUENCE});
            return events;
        }

        // Convert mapping
        if data is map<json> {
            events.push({startType: MAPPING, flowStyle: self.blockLevel <= depthLevel});

            string[] keys = data.keys();
            foreach string key in keys {
                events.push({value: key});
                events = self.combineArray(events, check self.serialize(data[key], depthLevel + 1));
            }

            events.push({endType: MAPPING});
            return events;
        }

        // Convert string
        // TODO: check the tag type
        events.push({value: data.toString()});
        return events;
    }

    function combineArray(Event[] firstEventsList, Event[] secondEventsList) returns Event[] {
        Event[] returnEventsList = firstEventsList.clone();

        secondEventsList.forEach(function(Event event) {
            returnEventsList.push(event);
        });

        return returnEventsList;
    }

    # Generates a Parsing Error.
    #
    # + message - Error message
    # + return - Constructed Parsing Error message  
    private function generateError(string message) returns SerializingError {
        return error SerializingError(string `Serializing Error: ${message}.`);
    }
}
