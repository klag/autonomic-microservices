include "public/interfaces/WriterInterface.iol"
include "public/interfaces/UpdaterInterface.iol"
include "file.iol"
include "console.iol"

execution{ sequential }

outputPort Updater {
    Location: "local://Updater"
    Protocol: sodep
    Interfaces: UpdaterInterface
}


inputPort Writer {
    Location: "auto:ini:/Locations/Writer:file:writerconfig.ini"
    Protocol: sodep
    Interfaces: WriterInterface
}

constants {
    LISTFILE = "hotellist.json"
}

define __writeFile {
    writeFile@File( { filename = LISTFILE, format = "json", content << global.list } )(  )
    update@Updater( global.list )()
   
}

init {
    readFile@File( { filename = LISTFILE, format = "json" } )( global.list )
    update@Updater( global.list )()
    println@Console( "writer is running..." )(  )
}

main {
    [ insertHotel( request )( response ) {
        for( h in global.list.hotel ) {
            if ( h.name == request.name ) { throw( NameAlreadyExist ) }
        }
        global.list.hotel[ #global.list.hotel ] << request 
        __writeFile
    }]

    [ updateHotel( request )( response ) {
        i = 0; found = false
        while( i < #global.list.hotel && !found ) {
            if ( global.list.hotel [ i ].name == request.name ) { found = true }
        }
        if ( found ) {
            global.list.hotel[ i ].rooms.available = global.list.hotel[ i ].rooms.total - request.rooms.booked
            __writeFile
        } else { throw( NameDoesNotExist ) }
    }]

    [ removeHotel( request )( response ) {
        i = 0; found = false
        while( i < #global.list.hotel && !found ) {
            if ( global.list.hotel [ i ].name == request.name ) { found = true }
        }
        if ( found ) {
            undef( global.list.hotel[ i ] )
            __writeFile
        } else { throw( NameDoesNotExist ) }
    }]
}