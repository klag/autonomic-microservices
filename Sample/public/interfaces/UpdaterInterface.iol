include "commons/types/Hotel.iol"

type UpdateRequest: void {
    hotel*: Hotel
}

interface UpdaterInterface {
RequestResponse:
    update( UpdateRequest )( void )
OneWay:
    addResource( void ),
    removeResource( void )
}