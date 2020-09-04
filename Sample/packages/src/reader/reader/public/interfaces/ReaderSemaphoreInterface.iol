type SubscriberNotification: void {
    token: string 
    location: any 
}


interface ReaderSemaphoreInterface {
    RequestResponse: 
        subscribeForNotification( SubscriberNotification )( void ),
        increment( void )( void ),
        decrement( void )( void )
}

type WakeUpRequest: void {
    token: string 
}

interface NotifierInterface {
    OneWay:
        wakeup( WakeUpRequest )
}