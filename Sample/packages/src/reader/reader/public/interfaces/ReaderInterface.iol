include "commons/types/Hotel.iol"

type GetHotelListRequest: void
type GetHotelListResponse: void {
    hotel*: Hotel
}

type GetHotelRequest: void {
    name: string
}

interface ReaderInterface {
    RequestResponse:
        getHotelList( GetHotelListRequest )( GetHotelListResponse ),
        getHotel( GetHotelRequest )( Hotel )
}