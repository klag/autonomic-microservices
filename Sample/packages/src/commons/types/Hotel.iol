
type Hotel: void {
    name: string 
    email: string
    address: string
    stars: int
    rooms: void {
        total: int 
        available: int
    }
}