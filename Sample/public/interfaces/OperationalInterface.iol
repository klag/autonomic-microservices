type UpRequest: void {
    name: string 
    instance: int
    zip: raw
    exposed_ports*: void {
        number: int
    }
}
type UpResponse: void {
    exposed_ports*: void {
        number: int 
        map: int
    }
}

type DownRequest: void {
    name: string 
    instance: int
}

interface OperationalInterface {
    RequestResponse: 
        up( UpRequest )( UpResponse ) throws StartingError,
        down( DownRequest )( void )
}