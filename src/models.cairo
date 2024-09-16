use starknet::ContractAddress;

#[derive(Copy, Drop, Serde, Introspect)]
#[dojo::model]
struct PlayerComponent {
    #[key]
    pub player_id: ContractAddress,
    pub username: String,
    pub moves_remaining: u8,
    pub deck: DeckComponent,
    pub hands: HandComponent,
    pub score: u32,
}

#[derive(Copy, Drop, Serde, Introspect)]
#[dojo::model]
pub struct HandComponent {
    pub cards: Array<Card>
}

#[derive(Copy, Drop, Serde, Introspect)]
#[dojo::model]
pub struct DeckComponent {
    pub cards: Array<Card>
}

#[derive(Copy, Drop, Serde, Introspect)]
#[dojo::model]
pub struct CardComponent {
    pub name: String,
    pub description: String,
    pub card_category: EnumCardCategory,
    pub value: u8,
    pub rank: u8
}

impl PlayerImpl for PlayerComponent {
    fn new(player_id: ContractAddress, username: String, moves_remaining: u8, score: u32) -> Self {
        return Self {
            player_id: player_id,
            username: username,
            moves_remaining: 3,
            score: score,
        };
    }
}

impl HandComponentImpl for HandComponent {
    fn new(cards: Array<Card>) -> Self {
        return Self {
            cards: cards,
        }
    }
}

impl DeckComponentImpl for DeckComponent {
    fn new(cards: Array<Card>) -> Self {
        return Self {
            cards: cards
        }
    }
}

impl CardComponentImpl for CardComponent {
    fn new(name: String, description: String, card_category: EnumCardCategory,
        value: u8, rank: u8) -> Self {
        return Self {
            name: name,
            description: description,
            card_category: card_category,
            value: value,
            rank: rank
        };
    }
    
    fn compare_rank_with(self: ref CardComponent, field: @CardComponent) -> EnumCardCompare {
        if self.rank > field.rank {
            return EnumCardCompare::Bigger();
        }
        
        if self.rank < field.rank {
            return EnumCardCompare::Smaller();
        }
        
        return EnumCardCompare::Equal();
    }
}

#[derive(Copy, Drop, Serde, ParitalEq, Introspect)]
enum EnumTxError {
    IncorrectTransaction: (),
    InvalidMove: (),
    UnknownPlayer: (),
    LobbyFull: (),
    LobbyDoesNotExist: ()
}

#[derive(Copy, Drop, Serde, ParitalEq, Introspect)]
enum EnumCardCompare {
    Smaller: (),
    Equal: (),
    Bigger: ()
}

#[derive(Copy, Drop, Serde, ParitalEq, Introspect)]
enum EnumCardCategory {
    Cash: (),
    Property: (),
    Special: ()
}

#[cfg(test)]
mod tests {
    use super::{CardComponent, Card, PlayerComponent, EnumCardCategory};

    #[test]
    fn test_is_equal() {
        let player = PlayerComponent::new("0xffffffffff", "nami2301", 3, 0);
        let card1 = CardComponent::new(player,
            name: "1M".to_string(),
            description: "1 Million Dollars".to_string(),
            card_type: EnumCardCategory::Cash,
            value: 1,
            rank: 0);
        
        let card2 = CardComponent::new(player,
            name: "2M".to_string(),
            description: "2 Million Dollars".to_string(),
            card_type: EnumCardCategory::Cash,
            value: 2,
            rank: 0);
        
        assert(card1.compare_rank_with(card2), 'Ranks should be equal');
    }
}
