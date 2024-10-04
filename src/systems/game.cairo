////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
/////////////////////            ____________  /////////////////////////
////////////////////    ___| |/ /_   _|_   _| //////////////////////////
////////////////////   |_  / ' /  | |   | |   //////////////////////////
////////////////////    / /| . \  | |   | |   //////////////////////////
////////////////////   /___|_|\_\ |_|   |_|   //////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

use zktt::models::components::{EnumCard, EnumGameState, EnumMoveError};
use starknet::ContractAddress;

#[dojo::interface]
trait ITable {
    fn join(ref world: IWorldDispatcher, username: ByteArray) -> ();
    fn start(ref world: IWorldDispatcher) -> ();
    fn new_turn(ref world: IWorldDispatcher) -> ();
    fn draw(ref world: IWorldDispatcher) -> ();
    fn play(ref world: IWorldDispatcher, card: EnumCard) -> ();
    fn move(ref world: IWorldDispatcher, card: EnumCard) -> ();
    fn end_turn(ref world: IWorldDispatcher) -> ();
    fn leave(ref world: IWorldDispatcher) -> ();
}

#[dojo::contract]
mod table {
    use super::{ITable};
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};
    use zktt::models::components::{ComponentDeck, ComponentDealer, ComponentHand, ComponentGame,
     ComponentMoneyPile, ComponentPlayer, EnumGameState, EnumMoveError,
      EnumCard, EnumPlayerState, EnumBlockchainType,
       IBlockchain, IDeck, IDealer, IEnumCard, IGame, IMoney, IPlayer, IHand, IAsset,
       StructAsset};

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// PUBLIC /////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    #[abi(embed_v0)]
    impl ITableImpl of ITable<ContractState> {
        fn join(ref world: IWorldDispatcher, username: ByteArray) -> () {
            let mut game = get!(world, (world.contract_address), (ComponentGame));
            assert!(game.m_state != EnumGameState::Started, "Game has already started");
            assert!(game.m_players.len() < 5, "Lobby already full");

            game.add_player(get_caller_address());
            let mut new_player: ComponentPlayer = IPlayer::new(get_caller_address(), username);
            new_player.m_state = EnumPlayerState::Joined;

            set!(world, (new_player, game));
            return ();
        }

        fn start(ref world: IWorldDispatcher) -> () {
            let seed = world.contract_address;
            let mut game: ComponentGame = get!(world, (seed), (ComponentGame));

            assert!(game.m_state != EnumGameState::Started, "Game has already started");
            assert!(game.m_players.len() >= 2, "Missing at least a player before starting");

            game.m_state = EnumGameState::Started;

            let mut dealer: ComponentDealer = IDealer::new(world.contract_address, create_cards(@seed));
            let mut world_ref = world;
            distribute_cards(ref world_ref, ref game.m_players, ref dealer.m_cards);
            set!(world, (dealer, game));
            return ();
        }

        fn new_turn(ref world: IWorldDispatcher) -> () {
            let game = get!(world, (world.contract_address), (ComponentGame));
            assert!(game.m_state == EnumGameState::Started, "Game has not started yet");

            let mut player = get!(world, get_caller_address(), (ComponentPlayer));
            assert!(player.m_state != EnumPlayerState::NotJoined, "Player not at table");
            assert!(player.m_state == EnumPlayerState::TurnEnded, "Not a valid turn");
            player.m_state = EnumPlayerState::TurnStarted;
            set!(world, (player));
        }

        fn draw(ref world: IWorldDispatcher) -> () {
            let seed = world.contract_address;
            let (mut hand, mut player) = get!(world, (get_caller_address()), (ComponentHand, ComponentPlayer));
            let game = get!(world, (world.contract_address), (ComponentGame));

            assert!(game.m_state == EnumGameState::Started, "Game has not started yet");
            assert!(player.m_state != EnumPlayerState::NotJoined, "Player not at table");
            assert!(player.m_state != EnumPlayerState::TurnEnded, "Not player's turn");
            assert!(player.m_moves_remaining != 0, "No moves left");

            let mut dealer = get!(world, (seed), ComponentDealer);
            let card_opt = dealer.pop_card();

            if card_opt.is_none() {
                panic!("Deck does not have any more cards!");
            }

            return match hand.add(card_opt.unwrap()) {
                Result::Ok(()) => {
                    player.m_state = EnumPlayerState::DrawnCards;
                    set!(world, (hand, player));
                    return ();
                },
                Result::Err(_) => panic!("Error adding card to hand of {0}", player.m_username)
            };
        }

        fn play(ref world: IWorldDispatcher, card: EnumCard) -> () {
            let game = get!(world, (world.contract_address), (ComponentGame));
            assert!(game.m_state == EnumGameState::Started, "Game has not started yet");

            let mut player = get!(world, get_caller_address(), (ComponentPlayer));
            assert!(player.m_state != EnumPlayerState::NotJoined, "Player not at table");
            assert!(player.m_state != EnumPlayerState::TurnEnded, "Not player's turn");
            assert!(player.m_state == EnumPlayerState::DrawnCards, "Player needs to draw cards first");
            assert!(player.m_moves_remaining != 0, "No moves left");

            let mut world_cpy = world;
            use_card(ref world_cpy, @get_caller_address(), card);

            player.m_moves_remaining -= 1;
            set!(world, (player));
            return ();
        }

        fn move(ref world: IWorldDispatcher, card: EnumCard) -> () {
            let game = get!(world, (world.contract_address), (ComponentGame));
            assert!(game.m_state == EnumGameState::Started, "Game has not started yet");

            let mut player = get!(world, get_caller_address(), (ComponentPlayer));
            assert!(player.m_state != EnumPlayerState::NotJoined, "Player not at table");
            assert!(player.m_state != EnumPlayerState::TurnEnded, "Not player's turn");
            assert!(player.m_state == EnumPlayerState::DrawnCards, "Player needs to draw cards first");

            assert!(@get_caller_address() == card.get_owner(), "Invalid owner");
            // TODO: Move card around in deck.
            set!(world, (player));
            return ();
        }

        fn end_turn(ref world: IWorldDispatcher) -> () {
            let game = get!(world, (world.contract_address), (ComponentGame));
            assert!(game.m_state == EnumGameState::Started, "Game has not started yet");

            let mut player = get!(world, get_caller_address(), (ComponentPlayer));
            assert!(player.m_state != EnumPlayerState::NotJoined, "Player not at table");
            assert!(player.m_state == EnumPlayerState::TurnStarted, "Not player's turn");

            player.m_state = EnumPlayerState::TurnEnded;
            set!(world, (player));
            return ();
        }

        fn leave(ref world: IWorldDispatcher) -> () {
            let mut game = get!(world, (world.contract_address), (ComponentGame));
            assert!(game.m_state == EnumGameState::Started, "Game has not started yet");

            let player = get!(world, (get_caller_address()), (ComponentPlayer));
            assert!(player.m_state != EnumPlayerState::NotJoined, "Player not at table");

            game.remove_player(@get_caller_address());
            delete!(world, (player));
            set!(world, (game));
            return ();
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// INTERNAL ///////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    fn use_card(ref world: IWorldDispatcher, caller: @ContractAddress, card: EnumCard) -> () {
        assert!(is_owner(@card, caller), "Invalid owner");
        let (mut hand, mut deck, mut money) = get!(world, (*caller), (ComponentHand, ComponentDeck, ComponentMoneyPile));
        hand.remove(@card);

        match card {
            EnumCard::Asset(asset) => {
                money.add(asset);
                set!(world, (money));
            },
            EnumCard::Blockchain(blockchain_struct) => {
                match deck.add(blockchain_struct) {
                    Result::Err(err) => panic!("{err}"),
                    _ => set!(world, (deck))
                };
            },
            EnumCard::Claim(mut gas_fee_struct) => {
                deck.remove(@gas_fee_struct.m_name);

                // Claim money.
                let total_claimed = *gas_fee_struct.m_multiplier.at(gas_fee_struct.m_count.into());
                // Check if the player playing it has the right blockchain to play this against.
                if gas_fee_struct.m_blockchain_type_affected != EnumBlockchainType::All &&
                    deck.contains_type(@gas_fee_struct.m_blockchain_type_affected).is_none() {
                    panic!("Invalid Gas Fee move");
                }

                let mut index = 0;
                loop {
                    if index >= gas_fee_struct.m_players_affected.len() {
                        break;
                    }

                    let current_player_addr = gas_fee_struct.m_players_affected.pop_front();
                    let mut player = get!(world, (current_player_addr), (ComponentMoneyPile));

                    money.m_total_value += player.m_total_value;
                    if player.m_total_value < total_claimed {
                        player.m_total_value = 0;
                        while !player.m_cards.is_empty() {
                            money.m_cards.append(player.m_cards.pop_front().unwrap());
                        };
                    } else {
                        let mut total_payed = 0;
                        while !player.m_cards.is_empty() && total_payed < total_claimed {
                            let card = player.m_cards.pop_front().unwrap();
                            total_payed = card.m_value;
                            money.m_cards.append(card);
                        };
                        player.m_total_value -= total_payed
                    }
                    set!(world, (player));
                };
                set!(world, (money, deck));
            },
            EnumCard::Deny(_majority_struct) => {
                //TODO: Add Say No card.
            },
            EnumCard::Draw(_draw_struct) => {
                 let mut dealer = get!(world, (world.contract_address), (ComponentDealer));
                 assert!(!dealer.m_cards.is_empty(), "Dealer has no more cards");
                 assert!(hand.add(dealer.pop_card().unwrap()).is_ok(), "cannot add card to hand");
                 assert!(hand.add(dealer.pop_card().unwrap()).is_ok(), "cannot add card to hand");
            },
            EnumCard::StealBlockchain(blockchain_struct) => {
                let mut opponent_deck = get!(world, (blockchain_struct.m_owner), (ComponentDeck));

                opponent_deck.remove(@blockchain_struct.m_name);
                match deck.add(blockchain_struct) {
                    Result::Err(err) => panic!("{err}"),
                    _ => set!(world, (deck, opponent_deck))
                };
            },
            EnumCard::StealAssetGroup(mut asset_group_struct) => {
                let mut opponent_deck = get!(world, (asset_group_struct.m_owner), (ComponentDeck));
                let mut player = get!(world, (*caller), (ComponentPlayer));
                let mut opponent_player = get!(world, (asset_group_struct.m_owner), (ComponentPlayer));

                player.m_sets += 1;
                opponent_player.m_sets -= 1;

                let mut index: usize = 0;
                while index < asset_group_struct.m_set.len() {
                    let blockchain = asset_group_struct.m_set.pop_front().unwrap();
                    opponent_deck.remove(@blockchain.m_name);

                    match deck.add(blockchain) {
                        Result::Err(err) => panic!("{err}"),
                        _ => {}
                    };
                    index += 1;
                };
                set!(world, (deck, opponent_deck, player, opponent_player));
            },
            _ => panic!("Invalid or illegal move!")
        };
        return ();
    }

    fn generate_seed(world_address: @ContractAddress, players: @Array<ContractAddress>) -> felt252 {
        // TODO: Generate random ordered card components for the beginning of the game.
        return (get_block_timestamp() * players.len().into() * 31).into();
    }

    fn create_cards(world_address: @ContractAddress) -> Array<EnumCard> {
        let mut container = ArrayTrait::new();

        // ASSET CARDS
        let asset = IAsset::new(*world_address, "ETH [1]", 1, 6);
        container.append(EnumCard::Asset(asset));

        let blockchain = IBlockchain::new(*world_address, "Base", EnumBlockchainType::LightBlue, 1, 2, 1);
        container.append(EnumCard::Blockchain(blockchain));

        let blockchain = IBlockchain::new(*world_address, "Arbitrum", EnumBlockchainType::LightBlue, 1, 2, 1);
        container.append(EnumCard::Blockchain(blockchain));

        let asset = IAsset::new(*world_address, "ETH [10]", 10, 1);
        container.append(EnumCard::Asset(asset));

        let blockchain = IBlockchain::new(*world_address, "Gnosis Chain", EnumBlockchainType::Green, 1, 1, 1);
        container.append(EnumCard::Blockchain(blockchain));

        let asset = IAsset::new(*world_address, "ETH [2]", 2, 5);
        container.append(EnumCard::Asset(asset));

        let blockchain = IBlockchain::new(*world_address, "Blast", EnumBlockchainType::Yellow,  2, 3, 1);
        container.append(EnumCard::Blockchain(blockchain));

        let blockchain = IBlockchain::new(*world_address, "Celestia", EnumBlockchainType::Purple,  2, 3, 1);
        container.append(EnumCard::Blockchain(blockchain));

        let asset = IAsset::new(*world_address, "ETH [5]", 5, 2);
        container.append(EnumCard::Asset(asset));

        let asset = IAsset::new(*world_address, "ETH [4]", 4, 3);
        container.append(EnumCard::Asset(asset));

        // Fantom
        let blockchain = IBlockchain::new(*world_address, "Fantom", EnumBlockchainType::LightBlue, 1, 2, 1);
        container.append(EnumCard::Blockchain(blockchain));

        let asset = IAsset::new(*world_address, "ETH [3]", 3, 3);
        container.append(EnumCard::Asset(asset));

        // Metis
        let blockchain = IBlockchain::new(*world_address, "Metis", EnumBlockchainType::LightBlue, 1, 2, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // GREEN
        // Canto
        let blockchain = IBlockchain::new(*world_address, "Canto", EnumBlockchainType::Green, 1, 1, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // Near
        let blockchain = IBlockchain::new(*world_address, "Near", EnumBlockchainType::Green, 1, 1, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // RED
        // Avalanche
        let blockchain = IBlockchain::new(*world_address, "Avalanche", EnumBlockchainType::Red, 2, 4, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // Kava
        let blockchain = IBlockchain::new(*world_address, "Kava", EnumBlockchainType::Red, 2, 4, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // Optimism
        let blockchain = IBlockchain::new(*world_address, "Optimism", EnumBlockchainType::Red, 2, 4, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // Grey
        // ZKSync
        let blockchain = IBlockchain::new(*world_address, "ZKSync", EnumBlockchainType::Grey, 1, 2, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // Linea
        let blockchain = IBlockchain::new(*world_address, "Linea", EnumBlockchainType::Grey, 1, 2, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // Aptos
        let blockchain = IBlockchain::new(*world_address, "Aptos", EnumBlockchainType::Grey, 1, 2, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // YELLOW
        // Scroll
        let blockchain = IBlockchain::new(*world_address, "Scroll", EnumBlockchainType::Yellow, 2, 3, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // Celo
        let blockchain = IBlockchain::new(*world_address, "Celo", EnumBlockchainType::Yellow,  2, 3, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // PURPLE
        // Polygon
        let blockchain = IBlockchain::new(*world_address, "Polygon", EnumBlockchainType::Purple, 2, 3, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // Solana
        let blockchain = IBlockchain::new(*world_address, "Solana", EnumBlockchainType::Purple,  2, 3, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // PINK
        // Polkadot
        let blockchain = IBlockchain::new(*world_address, "Polkadot", EnumBlockchainType::Pink, 1, 1, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // Osmosis
        let blockchain = IBlockchain::new(*world_address, "Osmosis", EnumBlockchainType::Pink, 1, 1, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // Taiko
        let blockchain = IBlockchain::new(*world_address, "Taiko", EnumBlockchainType::Pink, 1, 1, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // BLUE
        // Cosmos
        let blockchain = IBlockchain::new(*world_address, "Cosmos", EnumBlockchainType::Blue, 1, 1, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // Ton
        let blockchain = IBlockchain::new(*world_address, "Ton", EnumBlockchainType::Blue, 1, 1, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // DARK BLUE
        // Starknet
        let blockchain = IBlockchain::new(*world_address, "Starknet", EnumBlockchainType::DarkBlue, 3, 4, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // Ethereum
        let blockchain = IBlockchain::new(*world_address, "Ethereum", EnumBlockchainType::DarkBlue, 3, 4, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // GOLD
        // Bitcoin
        let blockchain = IBlockchain::new(*world_address, "Bitcoin", EnumBlockchainType::Gold, 1, 2, 1);
        container.append(EnumCard::Blockchain(blockchain));

        // Dogecoin
        let blockchain = IBlockchain::new(*world_address, "Dogecoin", EnumBlockchainType::Gold, 1, 2, 1);
        container.append(EnumCard::Blockchain(blockchain));
        
        return container;
    }

    fn distribute_cards(ref world: IWorldDispatcher, ref players: Array<ContractAddress>,
            ref cards: Array<EnumCard>) -> () {
        if players.is_empty() {
            panic!("There are no players to distribute cards to!");
        }

        return loop {
            if players.is_empty() || cards.is_empty()  {
                break ();
            }
            let current_player = players.pop_front().unwrap();
            let mut player_hand = get!(world, (current_player), (ComponentHand));

            let mut index: usize = 0;
            while index < 5 {
                if let Option::Some(card_given) = cards.pop_front() {
                    match player_hand.add(card_given) {
                        Result::Err(err) => {
                            // Maybe send an event.
                            panic!("Error happened when adding card Error => {0}", err);
                        },
                        _ => {}
                    };
                }

                index += 1;
            };

            set!(world, (player_hand));
        };
    }

    fn is_owner(card: @EnumCard, caller: @ContractAddress) -> bool {
        return card.get_owner() == caller;
    }

    fn shuffle(ref world: IWorldDispatcher) -> () {
        return ();
    }
}
