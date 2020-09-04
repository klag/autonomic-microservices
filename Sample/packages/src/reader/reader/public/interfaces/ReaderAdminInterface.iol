include "commons/types/Hotel.iol"

type RefreshListRequest: void {
    hotel*: Hotel
}

interface ReaderAdminInterface {
    RequestResponse:
        refreshList( RefreshListRequest )( void )
}