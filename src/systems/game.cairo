use zktt::models::{CardComponent, PlayerComponent, EnumCardCategory, EnumGameState, EnumMoveError};
use starknet::ContractAddress;

#[dojo::interface]
trait IGame {
    fn join(ref world: IWorldDispatcher, username: ByteArray) -> ();
    fn start(ref world: IWorldDispatcher) -> ();
    fn new_turn(ref world: IWorldDispatcher) -> ();
    fn draw(ref world: IWorldDispatcher) -> ();
    fn play(ref world: IWorldDispatcher, card: CardComponent) -> ();
    fn move(ref world: IWorldDispatcher, card: CardComponent) -> ();
    fn end_turn(ref world: IWorldDispatcher) -> ();
    fn leave(ref world: IWorldDispatcher) -> ();
    fn end(ref world: IWorldDispatcher) -> ();
}

#[dojo::contract]
mod game {
    use super::{IGame};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use zktt::models::{GameComponent, CardComponent, DeckComponent, DealerComponent,
     HandComponent, MoneyPileComponent, PlayerComponent, EnumGameState, EnumMoveError,
      EnumCardCategory, EnumPlayerState, EnumBlockchainType,
       IBlockchain, IDeck, IDealer, IGameComponent, IPlayer, ICard, IHand, IAsset};

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// PUBLIC /////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    #[abi(embed_v0)]
    impl IGameImpl of IGame<ContractState> {
        fn join(ref world: IWorldDispatcher, username: ByteArray) -> () {
            let mut game = get!(world, (world.contract_address), (GameComponent));
            assert!(game.state != EnumGameState::Started, "Game has already started");
            assert!(game.players.len() < 5, "Lobby already full");

            game.add_player(get_caller_address());
            let new_player: PlayerComponent = IPlayer::new(get_caller_address(), username);
            set!(world, (new_player, game));
            return ();
        }

        fn start(ref world: IWorldDispatcher) -> () {
            let seed = world.contract_address;
            let mut game = get!(world, (seed), (GameComponent));

            assert!(game.state != EnumGameState::Started, "Game has already started");
            assert!(game.players.len() >= 2, "Missing at least a player before starting");

            game.state = EnumGameState::Started;

            let mut dealer = IDealer::new(seed);
            let mut world_ref = world;

            dealer.cards = create_cards(@world.contract_address);
            // distribute_cards(ref world_ref, ref game.players, ref dealer.cards);
            set!(world, (dealer, game));
            return ();
        }

        fn new_turn(ref world: IWorldDispatcher) -> () {
            let game = get!(world, (world.contract_address), (GameComponent));
            assert!(game.state == EnumGameState::Started, "Game has not started yet");

            let mut player = get!(world, get_caller_address(), (PlayerComponent));
            assert!(player.state == EnumPlayerState::TurnEnded, "Not a valid turn");
            player.state = EnumPlayerState::TurnStarted;
            set!(world, (player));
        }

        fn draw(ref world: IWorldDispatcher) -> () {
            let seed = world.contract_address;
            let (mut hand, mut player) = get!(world, (get_caller_address()), (HandComponent, PlayerComponent));
            assert!(player.state == EnumPlayerState::TurnStarted, "Not a valid turn");
            assert!(player.moves_remaining != 0, "No moves left");

            let mut dealer = get!(world, (seed), DealerComponent);
            let card_opt = dealer.pop_card();

            if card_opt.is_none() {
                panic!("Deck does not have any more cards!");
            }

            let mut card = card_opt.unwrap();

            return match hand.add(ICard::new(get_caller_address(), card)) {
                Result::Ok(()) => {
                    player.moves_remaining -= 1;
                    set!(world, (hand, player));
                    return ();
                },
                Result::Err(_) => panic!("Error adding card to hand of {0}", player.username)
            };
        }

        fn play(ref world: IWorldDispatcher, card: CardComponent) -> () {
            assert!(get!(world, (world.contract_address), (GameComponent)).state == EnumGameState::Started,
                         "Game has not started yet");

            let mut player = get!(world, get_caller_address(), (PlayerComponent));
            assert!(player.moves_remaining != 0, "No moves left");

            let mut world_cpy = world;
            use_card(ref world_cpy, @get_caller_address(), card);

            player.moves_remaining -= 1;
            set!(world, (player));
            return ();
        }

        fn move(ref world: IWorldDispatcher, card: CardComponent) -> () {
            assert!(get!(world, (world.contract_address), (GameComponent)).state == EnumGameState::Started,
                                     "Game has not started yet");

            assert!(get_caller_address() == card.ent_owner, "Invalid owner");
            let mut player = get!(world, (get_caller_address()), (PlayerComponent));
            // TODO: Move card around in deck.
            set!(world, (player));
            return ();
        }

        fn end_turn(ref world: IWorldDispatcher) -> () {
            assert!(get!(world, (world.contract_address), (GameComponent)).state == EnumGameState::Started,
                         "Game has not started yet");

            let mut player = get!(world, get_caller_address(), (PlayerComponent));
            assert!(player.state == EnumPlayerState::TurnStarted, "Not a valid turn");

            player.state = EnumPlayerState::TurnEnded;
            set!(world, (player));
            return ();
        }

        fn leave(ref world: IWorldDispatcher) -> () {
            let player = get!(world, (get_caller_address()), (PlayerComponent));
            let mut game = get!(world, (world.contract_address), (GameComponent));

            if let Option::Some(_) = game.contains_player(@player.ent_owner) {
                game.remove_player(@get_caller_address());
                delete!(world, (player));
                set!(world, (game));
                return ();
            }

            panic!("Player not Found!");
        }

        fn end(ref world: IWorldDispatcher) -> () {
            let mut game = get!(world, (world.contract_address), (GameComponent));
            assert!(game.state == EnumGameState::Started, "Game has not started yet");

            game.state = EnumGameState::Ended;
            set!(world, (game));
            return ();
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// INTERNAL ///////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    fn use_card(ref world: IWorldDispatcher, caller: @ContractAddress, card: CardComponent) -> () {
        assert!(is_owner(@card, caller), "Invalid owner");
        let (mut hand, mut deck, mut money) = get!(world, (*caller), (HandComponent, DeckComponent, MoneyPileComponent));
        match card.category {
             EnumCardCategory::Draw(_) => {
                let mut dealer = get!(world, (world.contract_address), (DealerComponent));
                assert!(!dealer.cards.is_empty(), "Dealer has no more cards");
                assert!(hand.add(ICard::new(*caller, dealer.pop_card().unwrap())).is_ok(), "cannot add card to hand");
                assert!(hand.add(ICard::new(*caller, dealer.pop_card().unwrap())).is_ok(), "cannot add card to hand");
             },
             EnumCardCategory::Exchange((blockchain1, blockchain2)) => {
                // Swap cards from decks.
                let mut opponent_deck = get!(world, (blockchain2.ent_owner), DeckComponent);
                deck.remove(@blockchain1.ent_name);
                opponent_deck.remove(@blockchain2.ent_name);

                let bc1 = IBlockchain::new(blockchain2.ent_owner, blockchain1.ent_name, blockchain1.bc_type,
                blockchain1.fee, blockchain1.value, blockchain1.copies_left);
                let bc2 = IBlockchain::new(blockchain1.ent_owner, blockchain2.ent_name, blockchain2.bc_type,
                blockchain2.fee, blockchain2.value, blockchain2.copies_left);

                opponent_deck.blockchains.append(bc1.clone());
                deck.blockchains.append(bc2.clone());

                set!(world, (bc1, bc2, deck, opponent_deck));
             },
             EnumCardCategory::Claim(_gas_fee_component) => {},
             EnumCardCategory::Deny(_majority_component) => {},
             EnumCardCategory::StealBlockchain(_blockchain_component) => {},
             EnumCardCategory::StealAssetGroup(_asset_group_component) => {},
             EnumCardCategory::Asset(asset) => {
                money.total_value += asset.value;
                money.cards.append(asset);

                set!(world, (money));
             },
             EnumCardCategory::AssetGroup(_asset_group) => {},
             EnumCardCategory::Blockchain(blockchain) => {
                deck.blockchains.append(blockchain);
                set!(world, (deck));
             },
             EnumCardCategory::GasFee(_gas_fee) => {},
            _ => { panic!("Invalid or illegal move!"); }
        };
        return ();
    }

    fn generate_seed(world_address: @ContractAddress, players: @Array<ContractAddress>) -> felt252 {
        // TODO: Generate random ordered card components for the beginning of the game.
        return (get_block_timestamp() * players.len().into() * 31).into();
    }

    fn create_cards(world_address: @ContractAddress) -> Array<EnumCardCategory> {
        let mut container = ArrayTrait::new();

        // ASSET CARDS
        let asset = IAsset::new(*world_address, "ETH [1]", 1, 6);
        let ton = ICard::new(*world_address, EnumCardCategory::Asset(asset.clone()));
        container.append(EnumCardCategory::Asset(asset));


        let blockchain = IBlockchain::new(*world_address, "Base", EnumBlockchainType::LightBlue, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        let blockchain = IBlockchain::new(*world_address, "Arbitrum", EnumBlockchainType::LightBlue, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        let asset = IAsset::new(*world_address, "ETH [10]", 10, 1);
        let ton = ICard::new(*world_address, EnumCardCategory::Asset(asset.clone()));
        container.append(EnumCardCategory::Asset(asset));


        let blockchain = IBlockchain::new(*world_address, "Gnosis Chain", EnumBlockchainType::Green, 1, 1, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        let asset = IAsset::new(*world_address, "ETH [2]", 2, 5);
        let ton = ICard::new(*world_address, EnumCardCategory::Asset(asset.clone()));
        container.append(EnumCardCategory::Asset(asset));


        let blockchain = IBlockchain::new(*world_address, "Blast", EnumBlockchainType::Yellow,  2, 3, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        let blockchain = IBlockchain::new(*world_address, "Celestia", EnumBlockchainType::Purple,  2, 3, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        let asset = IAsset::new(*world_address, "ETH [5]", 5, 2);
        let ton = ICard::new(*world_address, EnumCardCategory::Asset(asset.clone()));
        container.append(EnumCardCategory::Asset(asset));


        let asset = IAsset::new(*world_address, "ETH [4]", 4, 3);
        let ton = ICard::new(*world_address, EnumCardCategory::Asset(asset.clone()));
        container.append(EnumCardCategory::Asset(asset));


        // Fantom
        let blockchain = IBlockchain::new(*world_address, "Fantom", EnumBlockchainType::LightBlue, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        let asset = IAsset::new(*world_address, "ETH [3]", 3, 3);
        let ton = ICard::new(*world_address, EnumCardCategory::Asset(asset.clone()));
        container.append(EnumCardCategory::Asset(asset));


        // Metis
        let blockchain = IBlockchain::new(*world_address, "Metis", EnumBlockchainType::LightBlue, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // GREEN
        // Canto
        let blockchain = IBlockchain::new(*world_address, "Canto", EnumBlockchainType::Green, 1, 1, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // Near
        let blockchain = IBlockchain::new(*world_address, "Near", EnumBlockchainType::Green, 1, 1, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // RED
        // Avalanche
        let blockchain = IBlockchain::new(*world_address, "Avalanche", EnumBlockchainType::Red, 2, 4, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // Kava
        let blockchain = IBlockchain::new(*world_address, "Kava", EnumBlockchainType::Red, 2, 4, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // Optimism
        let blockchain = IBlockchain::new(*world_address, "Optimism", EnumBlockchainType::Red, 2, 4, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // Silver
        // ZKSync
        let blockchain = IBlockchain::new(*world_address, "ZKSync", EnumBlockchainType::Silver, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // Linea
        let blockchain = IBlockchain::new(*world_address, "Linea", EnumBlockchainType::Silver, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // Aptos
        let blockchain = IBlockchain::new(*world_address, "Aptos", EnumBlockchainType::Silver, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // YELLOW
        // Scroll
        let blockchain = IBlockchain::new(*world_address, "Scroll", EnumBlockchainType::Yellow, 2, 3, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // Celo
        let blockchain = IBlockchain::new(*world_address, "Celo", EnumBlockchainType::Yellow,  2, 3, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // PURPLE
        // Polygon
        let blockchain = IBlockchain::new(*world_address, "Polygon", EnumBlockchainType::Purple, 2, 3, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // Solana
        let blockchain = IBlockchain::new(*world_address, "Solana", EnumBlockchainType::Purple,  2, 3, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // PINK
        // Polkadot
        let blockchain = IBlockchain::new(*world_address, "Polkadot", EnumBlockchainType::Pink, 1, 1, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // Osmosis
        let blockchain = IBlockchain::new(*world_address, "Osmosis", EnumBlockchainType::Pink, 1, 1, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // Taiko
        let blockchain = IBlockchain::new(*world_address, "Taiko", EnumBlockchainType::Pink, 1, 1, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // BLUE
        // Cosmos
        let blockchain = IBlockchain::new(*world_address, "Cosmos", EnumBlockchainType::Blue, 1, 1, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // Ton
        let blockchain = IBlockchain::new(*world_address, "Ton", EnumBlockchainType::Blue, 1, 1, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // DARK BLUE
        // Starknet
        let blockchain = IBlockchain::new(*world_address, "Starknet", EnumBlockchainType::DarkBlue, 3, 4, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // Ethereum
        let blockchain = IBlockchain::new(*world_address, "Ethereum", EnumBlockchainType::DarkBlue, 3, 4, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // GOLD
        // Bitcoin
        let blockchain = IBlockchain::new(*world_address, "Bitcoin", EnumBlockchainType::Gold, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));


        // Dogecoin
        let blockchain = IBlockchain::new(*world_address, "Dogecoin", EnumBlockchainType::Gold, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain.clone()));
        container.append(EnumCardCategory::Blockchain(blockchain));

        
        return container;
    }

    fn distribute_cards(ref world: IWorldDispatcher, ref players: Array<ContractAddress>,
            ref cards: Array<EnumCardCategory>) -> () {
        if players.is_empty() {
            panic!("There are no players to distribute cards to!");
        }

        let mut index = 0;
        let mut current_player = players.pop_front().unwrap();
        return loop {
            if index < players.len() {
                break ();
            }

            // Cycle through players every 5 cards given.
            if index != 0 && index % 5 == 0 {
                if let Option::Some(next_player) = players.pop_front() {
                    current_player = next_player;
                }
            }

            if let Option::Some(category) = cards.pop_front() {
                let mut player_hand = get!(world, (current_player), (HandComponent));
                let card = ICard::new(current_player, category);
                match player_hand.add(card) {
                    Result::Ok(()) => {
                        set!(world, (player_hand));
                    },
                    Result::Err(err) => {
                        // Maybe send an event.
                        panic!("Error happened when adding card Error => {0}", err);
                    }
                };
            }
            index += 1;
        };
    }

    fn is_owner(card: @CardComponent, caller: @ContractAddress) -> bool {
        return card.ent_owner == caller;
    }

    fn shuffle(ref world: IWorldDispatcher) -> () {
        return ();
    }

}
