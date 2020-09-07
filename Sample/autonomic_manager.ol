
include "public/interfaces/WriterInterface.iol"
include "reader/public/interfaces/ReaderInterface.iol"
include "reader/public/interfaces/ReaderAdminInterface.iol"
include "public/interfaces/UpdaterInterface.iol"
include "public/interfaces/OperationalInterface.iol"

include "console.iol"
include "string_utils.iol"
include "time.iol"
include "converter.iol"
include "zip_utils.iol"
include "file.iol"
include "runtime.iol"

execution{ concurrent }

outputPort Env {
    Location: "socket://localhost:9000"
    Protocol: sodep
    Interfaces: OperationalInterface
}

outputPort Writer {
    Location: "auto:ini:/Locations/Writer:file:writerconfig.ini"
    Protocol: sodep
    Interfaces: WriterInterface
}

outputPort ReaderAdmin {
    Protocol: sodep
    Interfaces: ReaderAdminInterface
}

outputPort Reader {
    Protocol: sodep
    Interfaces: ReaderInterface
}

outputPort MySelf {
    Location: "local://Updater"
    Protocol: sodep
    Interfaces: UpdaterInterface
}

inputPort Updater {
    Location: "local://Updater"
    Protocol: sodep
    Interfaces: UpdaterInterface
}


inputPort Aggregator {
    Location:  "auto:ini:/Locations/Aggregator:file:locations.ini"
    Protocol: sodep
    Aggregates: Reader, Writer
}

embedded {
    Jolie:
        "writer.ol" in Writer,
        "reader/reader.ol"
}

constants {
    HISTORY_MAX = 10,
    AVERAGE_MAX = 2600,
    AVERAGE_MIN = 150
}

define __calculate_resources {
    synchronized( update_history ) {
        if ( #global.history.responsetime > HISTORY_MAX ) {
            undef( global.history.responsetime[ 0 ] )
        }
        global.history.responsetime[ #global.history.responsetime ] = end - start
        if ( #global.history.responsetime > HISTORY_MAX ) {
            // check resources only if history is full
            sum = 0; for( i = 0, i < #global.history.responsetime, i++ ) { sum = sum + global.history.responsetime[ i ] }
            average = sum / #global.history.responsetime
            println@Console( "calculated average " + average )(  )

            if ( average > AVERAGE_MAX ) { addResource@MySelf() }

            if ( average < AVERAGE_MIN ) { removeResource@MySelf() }
        }
    }
}

courier Aggregator {
    [ interface ReaderInterface( request )( response ) ] {
        synchronized( calculate_r_index ) {
            global.r_index++
            if ( global.r_index >= #global.readers ) { global.r_index = 0 }
        }
        Reader.location = global.readers[ global.r_index ].pub 

        println@Console( "calling reader at location " + Reader.location )(  )
        getCurrentTimeMillis@Time()( start )
        forward( request )( response )

        // simulate response delay - begin
        if ( global.call_counter > 50 ) { global.call_counter.up = !global.call_counter.up;  global.call_counter = 0 }
        if ( global.call_counter.up ) { mult = global.call_counter } else { mult = 1 }
        global.call_counter++
        println@Console( "Simulating delay " + mult * 100 )(  )
        sleep@Time( mult * 100 )()
        println@Console( "global counter " + global.call_counter )(  )
        // end

        getCurrentTimeMillis@Time()( end )

        __calculate_resources
    }
}

init {
    enableTimestamp@Console( true )(  )
    global.call_counter = 0
    global.call_counter.up = true
    global.instance_index = 0
    global.readers[ 0 ] << {
        pub = "local://LocalReader"
        admin = "local://LocalReaderAdmin"
    } 
}

main {


    // from the writer for updating the cache of the readers
    [ update( request )( response ) {
        synchronized( cache ) {
            global.cache << request   
        }
        for( r = 0, r < #global.readers, r++ ) {
            ReaderAdmin.location = global.readers[ r ].admin
            refreshList@ReaderAdmin( request )() 
        }
    }]

    [ addResource( request ) ] {
                   
            // add a resource
            readFile@File( { filename = "lib/reader.jap", format = "binary" } )( japfile )
            zip_rq.("reader.jap") = japfile;
            readFile@File( { filename = "lib/commons.jap", format = "binary" } )( commons )
            zip_rq.("lib/commons.jap") = commons;
            stringToRaw@Converter("[Locations]\nAdmin=socket://localhost:8000\nReader=socket://localhost:8001")(inifile )
            zip_rq.("readerconfig.ini") = inifile 
            zip@ZipUtils( zip_rq )( request_up.zip )
            synchronized( up ) {
                request_up << {
                    exposed_ports[ 0 ].number = 8000
                    exposed_ports[ 1 ].number = 8001
                    name = "reader"
                    instance = global.instance_index
                }
                global.instance_index++
            }
 
            up@Env( request_up )( response_up )
            for( e in response_up.exposed_ports ) {
                if ( e.number == 8000 ) { admin = "socket://localhost:" + e.map }
                if ( e.number == 8001 ) { pub = "socket://localhost:" + e.map }
            }
            ReaderAdmin.location = admin
            scope( refresh ) {
                install( IOException => 
                    // the service could be not ready, wait and retry
                    sleep@Time( 3000 )(); refreshList@ReaderAdmin( global.cache )() 
                )
                println@Console( "Calling ReaderAdmin at " + ReaderAdmin.location )(  )
                refreshList@ReaderAdmin( global.cache )()
            } 

            synchronized( set_resource ) {
                reader_index = #global.readers
                global.readers[ reader_index ].admin = admin
                global.readers[ reader_index ].pub = pub
                global.readers[ reader_index ].instance = request_up.instance
            }
            
            // erasing the history because a new resourcehas been requested
            undef( global.history )
            println@Console( "Added resource reader" + request_up.instance )(  )
    }
    

    [ removeResource( request ) ] {
        synchronized( down ) {
            // release a resource
            if ( #global.readers > 1 ) {
                request_down.name = "reader"
                last_global_index = #global.readers - 1
                request_down.instance = global.readers[ last_global_index ].instance
                synchronized( set_resource ) {
                    undef( global.readers[ last_global_index ] )
                }
                down@Env( request_down )(  )
                println@Console( "Removed resource reader" + request_down.instance )(  )
            }
        }
        
    }

}