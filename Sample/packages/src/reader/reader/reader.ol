include "public/interfaces/ReaderInterface.iol"
include "public/interfaces/ReaderAdminInterface.iol"
include "public/interfaces/ReaderSemaphoreInterface.iol"
include "runtime.iol"

include "console.iol"

execution{ concurrent }

outputPort ReaderSemaphore {
    Interfaces: ReaderSemaphoreInterface
}

inputPort MySelf {
    Location: "local"
    Protocol: sodep
    Interfaces: NotifierInterface
}

inputPort Admin {
    Location: "auto:ini:/Locations/Admin:file:readerconfig.ini"
    Protocol: sodep
    Interfaces: ReaderAdminInterface
}

inputPort Reader {
    Location: "auto:ini:/Locations/Reader:file:readerconfig.ini"
    Protocol: sodep
    Interfaces: ReaderInterface
}

embedded {
    Jolie: "reader/reader_semaphore.ol" in ReaderSemaphore
}

cset {
    token: WakeUpRequest.token
}


init {
    getLocalLocation@Runtime()( subscriber_location )
    println@Console( "reader is running..." )(  )
}

main {
    [ refreshList( request )( response ) {
        synchronized( lock ) {
            csets.token = new 
            subscribeForNotification@ReaderSemaphore( { token = csets.token, location = subscriber_location })();wakeup( wkup )
            undef( global.hotel )
            global.hotel << request.hotel
            undef( global.index.by_name )
            // indexing by name
            for( h in request.hotel ) { global.index.by_name.( h.name ) << h }
        }
            
    }]

    [ getHotel( request )( response ) {
        synchronized( lock ) { increment@ReaderSemaphore()()  }
        response -> global.index.by_name
        decrement@ReaderSemaphore()()
    }]

    [ getHotelList( request )( response ) {
        synchronized( lock ) { increment@ReaderSemaphore()() }
        response.hotel -> global.hotel
        decrement@ReaderSemaphore()()
   }]
}

