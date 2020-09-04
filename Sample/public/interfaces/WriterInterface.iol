include "commons/types/Hotel.iol"

type RemoveHotelRequest: void {
    name: string
}

type UpdateHotelRequest: void {
    name: string
    rooms: void {
        booked: int
    }
}

interface WriterInterface {
    RequestResponse:
    insertHotel( Hotel )( void ) throws NameAlreadyExists,
    updateHotel( UpdateHotelRequest )( void ) throws ActionNotPermitted NameDoesNotExist,
    removeHotel( RemoveHotelRequest )( void ) throws NameDoesNotExist
}