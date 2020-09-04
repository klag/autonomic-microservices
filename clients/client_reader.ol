include "reader/public/interfaces/ReaderInterface.iol"

outputPort Sample {
    //Location: "auto:ini:/Locations/Aggregator:file:../Sample/locations.ini"
    Location: "socket://localhost:20000"
    Protocol: sodep
    Interfaces: ReaderInterface
}

main {
    for ( i = 0, i < int( args[ 0 ]), i++ ) {
        getHotelList@Sample( )( list )
    }
}