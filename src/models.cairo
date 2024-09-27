use starknet::ContractAddress;
use core::fmt::{Display, Formatter, Error};

////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////// COMPONENTS /////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

#[derive(Drop, Serde, Clone)]
#[dojo::model]
struct AssetComponent {
    #[key]
    ent_owner: ContractAddress,
    name: ByteArray,
    value: u8,
    copies_left: u8
}

#[derive(Drop, Serde)]
#[dojo::model]
struct AssetGroupComponent {
    #[key]
    ent_owner: ContractAddress,
    set: Array<BlockchainComponent>,
    total_fee_value: u8
}

#[derive(Drop, Serde, Clone)]
#[dojo::model]
struct BlockchainComponent {
    #[key]
    ent_owner: ContractAddress,
    #[key]
    ent_name: ByteArray,
    bc_type: EnumBlockchainType,
    fee: u8,
    value: u8,
    copies_left: u8
}

#[derive(Drop, Serde)]
#[dojo::model]
struct CardComponent {
    #[key]
    ent_owner: ContractAddress,
    category: EnumCardCategory,
}

#[derive(Drop, Serde)]
#[dojo::model]
struct DeckComponent {
    #[key]
    ent_owner: ContractAddress,
    blockchains: Array<BlockchainComponent>,
    asset_groups: Array<AssetGroupComponent>
}

#[derive(Drop, Serde)]
#[dojo::model]
struct DealerComponent {
    #[key]
    ent_owner: ContractAddress,
    cards: Array<EnumCardCategory>
}

#[derive(Drop, Serde)]
#[dojo::model]
struct GameComponent {
    #[key]
    pub seed: felt252,
    pub state: EnumGameState,
    pub players: Array<ContractAddress>
}

#[derive(Drop, Serde)]
#[dojo::model]
struct GasFeeComponent {
    #[key]
    ent_owner: ContractAddress,
    name: ByteArray,
    players_affected: Array<ContractAddress>,
    asset_group: Array<BlockchainComponent>,
    first_blockchain_type_affected: EnumBlockchainType,
    second_blockchain_type_affected: Option<EnumBlockchainType>,
    fee_per_player: u8,
    value: u8,
    copies_left: u8
}

#[derive(Drop, Serde)]
#[dojo::model]
struct HandComponent {
    #[key]
    ent_owner: ContractAddress,
    cards: Array<CardComponent>,
}

#[derive(Drop, Serde)]
#[dojo::model]
struct MajorityAttackComponent {
    #[key]
    ent_owner: ContractAddress,
    name: ByteArray,
    value: u8,
    copies_left: u8
}

#[derive(Drop, Serde)]
#[dojo::model]
struct MoneyPileComponent {
    #[key]
    ent_owner: ContractAddress,
    cards: Array<AssetComponent>,
    total_value: u8
}

#[derive(Drop, Serde)]
#[dojo::model]
struct PlayerComponent {
    #[key]
    ent_owner: ContractAddress,
    username: ByteArray,
    moves_remaining: u8,
    has_won: bool,
    score: u32,
    state: EnumPlayerState
}

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////// DISPLAY /////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

impl AssetDisplay of Display<AssetComponent> {
    fn fmt(self: @AssetComponent, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Name: {0}, Value: {1}, Copies Left: {2}",
         self.name, *self.value, *self.copies_left);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl AssetGroupDisplay of Display<AssetGroupComponent> {
    fn fmt(self: @AssetGroupComponent, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Total Fee: {0}", *self.total_fee_value);
        f.buffer.append(@str);

        let mut index = 0;
        while index < self.set.len() {
            if let Option::Some(blockchain) = self.set.get(index) {
                let str: ByteArray = format!("\nBlockchain: {0}", blockchain.unbox());
                f.buffer.append(@str);
            }
        };

        return Result::Ok(());
    }
}

impl BlockchainDisplay of Display<BlockchainComponent> {
    fn fmt(self: @BlockchainComponent, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Name: {0}, Type: {1}, Fee: {2}, Value {3}, Copies Left: {4}",
         self.ent_name, self.bc_type, *self.fee, *self.value, *self.copies_left);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl CardDisplay of Display<CardComponent> {
    fn fmt(self: @CardComponent, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Category: {0}", self.category);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl EnumCardCategoryDisplay of Display<EnumCardCategory> {
    fn fmt(self: @EnumCardCategory, ref f: Formatter) -> Result<(), Error> {
        match self {
            EnumCardCategory::Asset(component) => {
                let str: ByteArray = format!("Asset: ({component})");
                f.buffer.append(@str);
            },
            EnumCardCategory::AssetGroup(component) => {
                let str: ByteArray = format!("AssetGroup: ({component})");
                f.buffer.append(@str);
            },
            EnumCardCategory::Blockchain(component) => {
                let str: ByteArray = format!("Blockchain: ({component})");
                f.buffer.append(@str);
            },
            EnumCardCategory::Claim(component) => {
                let str: ByteArray = format!("Claim: ({component})");
                f.buffer.append(@str);
            },
            EnumCardCategory::Deny(component) => {
                let str: ByteArray = format!("Deny: ({component})");
                f.buffer.append(@str);
            },
            EnumCardCategory::Draw(_) => {
                let str: ByteArray = format!("Draw two cards");
                f.buffer.append(@str);
            },
            EnumCardCategory::Exchange((blockchain1, blockchain2)) => {
                let str: ByteArray = format!("Exchange: ({blockchain1}, {blockchain2})");
                f.buffer.append(@str);
            },
            EnumCardCategory::GasFee(gas_fee_component) => {
                let str: ByteArray = format!("GasFee: ({gas_fee_component})");
                f.buffer.append(@str);
            },
            EnumCardCategory::StealBlockchain(blockchain) => {
                let str: ByteArray = format!("Steal Blockchain: ({blockchain})");
                f.buffer.append(@str);
            },
            EnumCardCategory::StealAssetGroup(asset_group) => {
                let str: ByteArray = format!("Steal Asset Group: ({asset_group})");
                f.buffer.append(@str);
            },
            _ => {}
        };
        return Result::Ok(());
    }
}

impl EnumBlockchainTypeDisplay of Display<EnumBlockchainType> {
    fn fmt(self: @EnumBlockchainType, ref f: Formatter) -> Result<(), Error> {
        match self {
            EnumBlockchainType::Black(_) => {
                let str: ByteArray = format!("Black");
                f.buffer.append(@str);
            },
            EnumBlockchainType::Blue(_) => {
                let str: ByteArray = format!("Blue");
                f.buffer.append(@str);
            },
            EnumBlockchainType::DarkBlue(_) => {
                let str: ByteArray = format!("Dark Blue");
                f.buffer.append(@str);
            },
            EnumBlockchainType::Gold(_) => {
                let str: ByteArray = format!("Gold");
                f.buffer.append(@str);
            },
            EnumBlockchainType::Green(_) => {
                let str: ByteArray = format!("Green");
                f.buffer.append(@str);
            },
            EnumBlockchainType::LightBlue(_) => {
                let str: ByteArray = format!("Light Blue");
                f.buffer.append(@str);
            },
            EnumBlockchainType::Pink(_) => {
                let str: ByteArray = format!("Pink");
                f.buffer.append(@str);
            },
            EnumBlockchainType::Purple(_) => {
                let str: ByteArray = format!("Purple");
                f.buffer.append(@str);
            },
            EnumBlockchainType::Red(_) => {
                let str: ByteArray = format!("Red");
                f.buffer.append(@str);
            },
            EnumBlockchainType::Silver(_) => {
                let str: ByteArray = format!("Silver");
                f.buffer.append(@str);
            },
            EnumBlockchainType::Yellow(_) => {
                let str: ByteArray = format!("Yellow");
                f.buffer.append(@str);
            },
        };
        return Result::Ok(());
    }
}

impl EnumMoveErrorDisplay of Display<EnumMoveError> {
    fn fmt(self: @EnumMoveError, ref f: Formatter) -> Result<(), Error> {
        match self {
            EnumMoveError::TooManyCardsHeld(_) => {
                let str: ByteArray = format!("Too Many Cards Held!");
                f.buffer.append(@str);
            },
            EnumMoveError::CardNotFound(_) => {
                let str: ByteArray = format!("Card Not found!");
                f.buffer.append(@str);
            },
            EnumMoveError::NotEnoughMoves(_) => {
                let str: ByteArray = format!("Not Enough Moves to Proceed!");
                f.buffer.append(@str);
            }
        };
        return Result::Ok(());
    }
}

impl GasFeeDisplay of Display<GasFeeComponent> {
    fn fmt(self: @GasFeeComponent, ref f: Formatter) -> Result<(), Error> {
        if let Option::Some(second_bc_affected) = self.second_blockchain_type_affected {
            let str: ByteArray = format!("Name: {0}, First Targeted Blockchain: {1}, Second (opt)
                Targeted Blockchain: {2}, Value: {3}, Fees Per Player: {4}, Copies Left: {5}",
                self.name, self.first_blockchain_type_affected, second_bc_affected, *self.value,
                *self.fee_per_player, *self.copies_left);
            f.buffer.append(@str);
            return Result::Ok(());
        }

        let str: ByteArray = format!("Name: {0}, First Targeted Blockchain: {1}, Value: {2}\n
            Fees Per Player: {3}, Copies Left: {4}", self.name, self.first_blockchain_type_affected,
             *self.value, *self.fee_per_player, *self.copies_left);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl MajorityAttackDisplay of Display<MajorityAttackComponent> {
    fn fmt(self: @MajorityAttackComponent, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Name: {0}, Value: {1}, Copies Left: {2}", self.name,
            *self.value, *self.copies_left);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl PlayerDisplay of Display<PlayerComponent> {
    fn fmt(self: @PlayerComponent, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Username: {0}, Has won: {1}, Moves remaining: {2},
            Score: {3}", self.username, *self.has_won, *self.moves_remaining, *self.score);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
/////////////////////////////// TRAITS /////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

#[generate_trait]
impl AssetImpl of IAsset {
    fn new(owner: ContractAddress, name: ByteArray, value: u8, copies_left: u8) -> AssetComponent {
        return AssetComponent {
            ent_owner: owner,
            name: name,
            value: value,
            copies_left: copies_left
        };
    }
}

#[generate_trait]
impl BlockchainImpl of IBlockchain {
    fn new(owner: ContractAddress, name: ByteArray, bc_type: EnumBlockchainType, fee: u8, value: u8, copies_left: u8) -> BlockchainComponent {
        return BlockchainComponent {
            ent_owner: owner,
            ent_name: name,
            bc_type: bc_type,
            fee: fee,
            value: value,
            copies_left: copies_left
        };
    }
}

#[generate_trait]
impl CardImpl of ICard {
    fn new(owner: ContractAddress, category: EnumCardCategory) -> CardComponent {
        return CardComponent {
            ent_owner: owner,
            category: category
        };
    }
}

#[generate_trait]
impl DealerImpl of IDealer {
    fn new(seed: ContractAddress) -> DealerComponent {
        return DealerComponent {
            ent_owner: seed,
            cards: array![]
        };
    }

    fn pop_card(ref self: DealerComponent) -> Option<EnumCardCategory> {
        if self.cards.is_empty() {
            return Option::None;
        }

        return self.cards.pop_front();
    }
}

#[generate_trait]
impl DeckImpl of IDeck {
    fn contains_bc(ref self: DeckComponent, bc_name : @ByteArray) -> Option<usize> {
        let mut index = 0;
        let mut found = Option::None;

        while index < self.blockchains.len() {
            if let Option::Some(bc_found) = self.blockchains.get(index) {
                if bc_name == bc_found.unbox().ent_name {
                    found = Option::Some(index);
                    break;
                }
            }
        };
        return found;
    }

    fn remove(ref self: DeckComponent, card_name: @ByteArray) -> () {
        if let Option::Some(index_found) = self.contains_bc(card_name) {
            let mut new_array = ArrayTrait::new();

            let mut index = 0;
            return loop {
                if index >= self.blockchains.len() {
                    break ();
                }

                if index == index_found {
                    continue;
                }

                new_array.append((self.blockchains.at(index)).clone());
                index += 1;
            };
        }
    }
}

#[generate_trait]
impl GameImpl of IGameComponent {
    fn add_player(ref self: GameComponent, mut new_player: ContractAddress) -> () {
        assert!(self.contains_player(@new_player).is_none(), "Player already exists");
        self.players.append(new_player);
        return ();
    }

    fn contains_player(self: @GameComponent, player: @ContractAddress) -> Option<usize> {
        let mut index = 0;
        let mut found = Option::None;

        while index < self.players.len() {
            if let Option::Some(player_found) = self.players.get(index) {
                if player == player_found.unbox() {
                    found = Option::Some(index);
                    break;
                }
            }
            index += 1;
        };
        return found;
    }

    fn remove_player(ref self: GameComponent, player: @ContractAddress) -> () {
        if let Option::Some(index_found) = self.contains_player(player) {
            let mut new_array = ArrayTrait::new();

            let mut index = 0;
            return loop {
                if index >= self.players.len() {
                    break ();
                }

                if index == index_found {
                    continue;
                }

                new_array.append(*self.players.at(index));
                index += 1;
            };
        }
    }
}

#[generate_trait]
impl HandImpl of IHand {
    fn add(ref self: HandComponent, card: CardComponent) -> Result<(), EnumMoveError> {
        if self.cards.len() == 9 {
            return Result::Err(EnumMoveError::TooManyCardsHeld);
        }

        self.cards.append(card);
        return Result::Ok(());
    }
}

#[generate_trait]
impl PlayerImpl of IPlayer {
    fn new(owner: ContractAddress, username: ByteArray) -> PlayerComponent {
        return PlayerComponent {
            ent_owner: owner,
            username: username,
            has_won: false,
            moves_remaining: 3,
            score: 0,
            state: EnumPlayerState::TurnEnded
        };
    }
}

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
/////////////////////////////// ENUMS /////////////////////////////////
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
enum EnumGameState {
    WaitingForPlayers: (),
    Started: (),
    Ended: ()
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
enum EnumPlayerState {
    TurnStarted: (),
    TurnEnded: (),
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect)]
enum EnumMoveError {
    TooManyCardsHeld: (),
    CardNotFound: (),
    NotEnoughMoves: ()
}

#[derive(Drop, Serde, Introspect)]
enum EnumCardCategory {
    Asset: AssetComponent,
    AssetGroup: AssetGroupComponent,
    Blockchain: BlockchainComponent,
    Claim: GasFeeComponent,  // Make other player(s) pay you a fee.
    Deny: MajorityAttackComponent,  // Deny and avoid performing the action imposed.
    Draw: (), // Draw two additional cards.
    Exchange: (BlockchainComponent, BlockchainComponent),  // Swap a blockchain with another player.
    GasFee: GasFeeComponent,
    StealBlockchain: BlockchainComponent,  // Steal a single blockchain from a player's deck.
    StealAssetGroup: AssetGroupComponent,  // Steal Asset Group from another player.
}

#[derive(Drop, Serde, Clone, Introspect)]
enum EnumBlockchainType {
    Black: (),
    Blue: (),
    DarkBlue: (),
    Gold: (),
    Green: (),
    LightBlue: (),
    Pink: (),
    Purple: (),
    Red: (),
    Silver: (),
    Yellow: ()
}