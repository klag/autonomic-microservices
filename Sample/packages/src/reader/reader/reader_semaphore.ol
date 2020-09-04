include "public/interfaces/ReaderSemaphoreInterface.iol"
include "console.iol"

execution{ sequential  }

outputPort Notifier {
    Interfaces: NotifierInterface
}

inputPort Semaphore {
    Location: "local"
    Protocol: sodep
    Interfaces: ReaderSemaphoreInterface
}

define __checkNotification {
    if ( #global.subscriber_list > 0 && global.reader == 0 ) {
        for( s = 0, s < #global.subscriber_list, s++ ) {
            Notifier.location = global.subscriber_list[ s ].location
            wakeup@Notifier( { token = global.subscriber_list[ s ].token } )
        }
        undef( global.subscriber_list )
    } 
}

init {
    global.reader = 0
}

main {
    [ increment( request )( response ) {
        global.reader++
        __checkNotification
    }]

    [ decrement( request )( response )  {
        global.reader--
        __checkNotification
    }]

    [ subscribeForNotification( request )( response ) {
        global.subscriber_list[ #global.subscriber_list ] << {
            token = request.token
            location = request.location
        } 
        __checkNotification
    }]
}