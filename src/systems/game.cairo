////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////  ______  __  __   ______  ______   ////////////////////////////////
//////////////////////////////// /\___  \/\ \/ /  /\__  _\/\__  _\  ////////////////////////////////
//////////////////////////////// \/_/  /_\ \  _`-.\/_/\ \/\/_/\ \/  ////////////////////////////////
////////////////////////////////   /\_____\ \_\ \_\  \ \_\   \ \_\  ////////////////////////////////
////////////////////////////////   \/_____/\/_/\/_/   \/_/    \/_/  ////////////////////////////////
////////////////////////////////                                    ////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024 zkTT
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the Software
// is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
// THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
////////////////////////////////////////////////////////////////////////////////////////////////////

use zktt::models::components::{EnumCard, EnumGameState, EnumMoveError};
use starknet::ContractAddress;

#[dojo::interface]
trait ITable {
    fn join(ref world: IWorldDispatcher, username: ByteArray) -> ();
    fn start(ref world: IWorldDispatcher) -> ();
    fn new_turn(ref world: IWorldDispatcher) -> ();
    fn draw(ref world: IWorldDispatcher, draws_five: bool) -> ();
    fn play(ref world: IWorldDispatcher, card: EnumCard) -> ();
    fn move(ref world: IWorldDispatcher, card: EnumCard) -> ();
    fn pay_fee(ref world: IWorldDispatcher, pay: Array<EnumCard>, recipient: ContractAddress,
        payee: ContractAddress) -> ();
    fn end_turn(ref world: IWorldDispatcher) -> ();
    fn leave(ref world: IWorldDispatcher) -> ();
}

#[dojo::contract]
mod table {
    use super::{ITable};
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};
    use zktt::models::components::{ComponentCard, ComponentDealer, ComponentDeck, ComponentDeposit,
     ComponentHand, ComponentGame, ComponentPlayer, EnumGameState, EnumMoveError,
      EnumCard, EnumPlayerState, EnumBlockchainType,
       IBlockchain, ICard, IDeck, IDealer, IEnumCard, IGame, IGasFee, IDeposit, IPlayer, IHand, IAsset,
       StructAsset};

    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// PUBLIC /////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////

    /// Only run once when contract is deployed.
    fn dojo_init(ref world: IWorldDispatcher) {
       // Step 1: Create cards and put them in a container in order.
       let cards_in_order: Array<EnumCard> =
       array![EnumCard::Asset(IAsset::new(Option::Some(world.contract_address), "ETH [1]", 1, 6)),
       EnumCard::Asset(IAsset::new(Option::Some(world.contract_address), "ETH [2]", 2, 5)),
       EnumCard::Asset(IAsset::new(Option::Some(world.contract_address), "ETH [3]", 3, 3)),
       EnumCard::Asset(IAsset::new(Option::Some(world.contract_address), "ETH [4]", 4, 3)),
       EnumCard::Asset(IAsset::new(Option::Some(world.contract_address), "ETH [5]", 5, 2)),
       EnumCard::Asset(IAsset::new(Option::Some(world.contract_address), "ETH [10]", 10, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Aptos", EnumBlockchainType::Grey, 1, 2, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Arbitrum", EnumBlockchainType::LightBlue, 1, 2, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Avalanche", EnumBlockchainType::Red, 2, 4, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Base", EnumBlockchainType::LightBlue, 1, 2, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Bitcoin", EnumBlockchainType::Gold, 1, 2, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Blast", EnumBlockchainType::Yellow,  2, 3, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Canto", EnumBlockchainType::Green, 1, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Celestia", EnumBlockchainType::Purple,  2, 3, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Celo", EnumBlockchainType::Yellow,  2, 3, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Cosmos", EnumBlockchainType::Blue, 1, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Dogecoin", EnumBlockchainType::Gold, 1, 2, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Ethereum", EnumBlockchainType::DarkBlue, 3, 4, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Fantom", EnumBlockchainType::LightBlue, 1, 2, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Gnosis Chain", EnumBlockchainType::Green, 1, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Kava", EnumBlockchainType::Red, 2, 4, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Linea", EnumBlockchainType::Grey, 1, 2, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Metis", EnumBlockchainType::LightBlue, 1, 2, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Near", EnumBlockchainType::Green, 1, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Optimism", EnumBlockchainType::Red, 2, 4, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Osmosis", EnumBlockchainType::Pink, 1, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Polkadot", EnumBlockchainType::Pink, 1, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Polygon", EnumBlockchainType::Purple, 2, 3, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Scroll", EnumBlockchainType::Yellow, 2, 3, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Solana", EnumBlockchainType::Purple,  2, 3, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Starknet", EnumBlockchainType::DarkBlue, 3, 4, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Taiko", EnumBlockchainType::Pink, 1, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Ton", EnumBlockchainType::Blue, 1, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "ZKSync", EnumBlockchainType::Grey, 1, 2, 1))
        ];

       let dealer: ComponentDealer = IDealer::new(world.contract_address, cards_in_order);

       // Step 2: Register all these cards initially in the world for dealer as the owner.
       let mut index: usize = 0;
       while index < dealer.m_cards.len() {
           // Register the card's new owner.
           let card = dealer.m_cards.at(index);
           set!(world, (ICard::new(world.contract_address, card.clone())));
           index += 1;
       };

       set!(world, (dealer));
    }

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

            // Step 2: Create another container with shuffled cards using seed and pseudo-random algorithm.
            let seed: felt252 = generate_seed(@world.contract_address, @game.m_players);
            let mut dealer = get!(world, (world.contract_address), (ComponentDealer));
            dealer.shuffle(seed);

            // Step 3: Distribute 5 cards per player by drawing from the dealer's deck.
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
            assert!(player.m_state == EnumPlayerState::TurnEnded ||
                player.m_state == EnumPlayerState::Joined, "Player has already started turn");
            player.m_state = EnumPlayerState::TurnStarted;
            set!(world, (player));
        }

        fn draw(ref world: IWorldDispatcher, draws_five: bool) -> () {
            let seed = world.contract_address;
            let (mut hand, mut player) = get!(world, (get_caller_address()), (ComponentHand,
             ComponentPlayer));
            let game = get!(world, (world.contract_address), (ComponentGame));

            assert!(game.m_state == EnumGameState::Started, "Game has not started yet");
            assert!(player.m_state != EnumPlayerState::NotJoined, "Player not at table");
            assert!(player.m_state == EnumPlayerState::TurnStarted, "Not player's turn");
            assert!(player.m_moves_remaining == 3, "Cannot draw mid-turn");

            let mut dealer = get!(world, (seed), ComponentDealer);
            if draws_five {
                assert!(hand.m_cards.len() == 0, "Cannot draw five, hand not empty");
                let mut index: usize = 0;
                let mut ref_world = world;

                while index < 5 {
                    if dealer.m_cards.is_empty() {
                        panic!("Dealer has no more cards");
                    }

                    let card = dealer.pop_card().unwrap();
                    register_card(ref ref_world, card.clone(), get_caller_address());

                    hand.add(card);
                };

                player.m_state = EnumPlayerState::DrawnCards;
                set!(world, (hand, dealer, player));
                return ();
            }

            let mut dealer = get!(world, (seed), ComponentDealer);
            let card1_opt = dealer.pop_card();
            let card2_opt = dealer.pop_card();

            if card1_opt.is_none() || card2_opt.is_none() {
                panic!("Deck does not have any more cards!");
            }

            // Draw two cards.
            hand.add(card1_opt.unwrap());
            hand.add(card2_opt.unwrap());
            player.m_state = EnumPlayerState::DrawnCards;
            set!(world, (hand, dealer, player));
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
            assert!(is_owner(@world_cpy, @card, @get_caller_address()), "Player does not own card");
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

            let mut world_cpy = world;
            assert!(is_owner(@world_cpy, @card, @get_caller_address()), "Player does not own card");
            // TODO: Move card around in deck.
            set!(world, (player));
            return ();
        }

        fn pay_fee(ref world: IWorldDispatcher, mut pay: Array<EnumCard>, recipient: ContractAddress, payee: ContractAddress) -> () {
            let game = get!(world, (world.contract_address), (ComponentGame));
            assert!(game.m_state == EnumGameState::Started, "Game has not started yet");

            let (mut player, mut payee_stash, mut payee_deck) = get!(world, (payee), (ComponentPlayer,
                ComponentDeposit, ComponentDeck));
            assert!(player.get_debt().is_some(), "Player is not in debt");

            let mut recipient_stash = get!(world, (recipient), (ComponentDeposit));
            let mut recipient_deck = get!(world, (recipient), (ComponentDeck));

            while let Option::Some(card) = pay.pop_front() {
                // Give assets or action cards as payment.
                if !card.is_blockchain() {
                    payee_stash.remove(@card);
                    recipient_stash.add(card);
                    continue;
                }

                // Give blockchains as payment.
                payee_deck.remove(@card);
                recipient_deck.add(card);
            };

            // Remove player's debt.
            player.m_in_debt = Option::None;
            set!(world, (recipient_stash, recipient_deck, payee_stash, payee_deck, player));
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

            let (mut hand, mut deck, mut deposit) = get!(world, (player.m_ent_owner), (ComponentHand,
            ComponentDeck, ComponentDeposit));

            // TODO: Cleanup after player by setting all card owner's to 0.
            // hand.discard_cards();
            // deck.discard_cards();
            // deposit.discard_cards();

            game.remove_player(@get_caller_address());
            delete!(world, (player, hand, deck, deposit));
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
        let (mut hand, mut deck, mut deposit) = get!(world, (*caller), (ComponentHand, ComponentDeck, ComponentDeposit));
        hand.remove(@card);

        match card {
            EnumCard::Asset(asset) => {
                deposit.add(EnumCard::Asset(asset));
                set!(world, (deposit));
            },
            EnumCard::Blockchain(blockchain_struct) => {
                deck.add(EnumCard::Blockchain(blockchain_struct));
                set!(world, (deck));
            },
            EnumCard::Claim(mut gas_fee_struct) => {
                // Check if the player playing it has the right blockchain to play this against.
                if gas_fee_struct.m_blockchain_type_affected != EnumBlockchainType::Immutable &&
                    deck.contains_type(@gas_fee_struct.m_blockchain_type_affected).is_none() {
                    panic!("Invalid Gas Fee move");
                }

                let fee = gas_fee_struct.get_fee();
                if fee.is_none() {
                    panic!("Invalid Gas Fee move");
                }

                // Make every affected player in debt for their next turn.
                while let Option::Some(player) = gas_fee_struct.m_players_affected.pop_front() {
                    let mut player_component = get!(world, (player), (ComponentPlayer));
                    player_component.m_in_debt = fee;
                    set!(world, (player_component));
                };
            },
            EnumCard::Deny(_majority_struct) => {
                //TODO: Add Hardfork card.
            },
            EnumCard::Draw(_draw_struct) => {
                 let mut dealer = get!(world, (world.contract_address), (ComponentDealer));
                 assert!(!dealer.m_cards.is_empty(), "Dealer has no more cards");

                 hand.add(dealer.pop_card().unwrap());
                 hand.add(dealer.pop_card().unwrap());
                 set!(world, (hand, dealer));
            },
            EnumCard::StealBlockchain(blockchain_struct) => {
                let mut opponent_deck = get!(world, (blockchain_struct.m_owner), (ComponentDeck));
                let card = EnumCard::Blockchain(blockchain_struct.clone());
                opponent_deck.remove(@card);
                deck.add(EnumCard::StealBlockchain(blockchain_struct));
                set!(world, (deck, opponent_deck));
            },
            EnumCard::StealAssetGroup(mut asset_group_struct) => {
                let mut opponent_deck = get!(world, (asset_group_struct.m_owner), (ComponentDeck));
                let mut player = get!(world, (*caller), (ComponentPlayer));
                let mut opponent_player = get!(world, (asset_group_struct.m_owner), (ComponentPlayer));

                player.m_sets += 1;
                opponent_player.m_sets -= 1;

                let mut index: usize = 0;
                while index < asset_group_struct.m_set.len() {
                    let card = EnumCard::Blockchain(asset_group_struct.m_set.pop_front().unwrap());
                    opponent_deck.remove(@card);
                    deck.add(card);
                    index += 1;
                };
                set!(world, (deck, opponent_deck, player, opponent_player));
            },
            _ => panic!("Invalid or illegal move!")
        };


        return ();
    }

    fn generate_seed(world_address: @ContractAddress, players: @Array<ContractAddress>) -> felt252 {
        let mut seed: felt252 = 0;

        let mut index: usize = 0;
        while index < players.len() {
            seed += get_block_timestamp().into();
            index += 1;
        };
        seed *= players.len().into();
        return seed;
    }

    fn create_cards(ref world: IWorldDispatcher) -> () {
        // Step 1: Create cards and put them in a container in order.
       let cards_in_order: Array<EnumCard> =
       array![EnumCard::Asset(IAsset::new(Option::Some(world.contract_address), "ETH [1]", 1, 6)),
       EnumCard::Asset(IAsset::new(Option::Some(world.contract_address), "ETH [2]", 2, 5)),
       EnumCard::Asset(IAsset::new(Option::Some(world.contract_address), "ETH [3]", 3, 3)),
       EnumCard::Asset(IAsset::new(Option::Some(world.contract_address), "ETH [4]", 4, 3)),
       EnumCard::Asset(IAsset::new(Option::Some(world.contract_address), "ETH [5]", 5, 2)),
       EnumCard::Asset(IAsset::new(Option::Some(world.contract_address), "ETH [10]", 10, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Aptos", EnumBlockchainType::Grey, 1, 2, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Arbitrum", EnumBlockchainType::LightBlue, 1, 2, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Avalanche", EnumBlockchainType::Red, 2, 4, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Base", EnumBlockchainType::LightBlue, 1, 2, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Bitcoin", EnumBlockchainType::Gold, 1, 2, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Blast", EnumBlockchainType::Yellow,  2, 3, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Canto", EnumBlockchainType::Green, 1, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Celestia", EnumBlockchainType::Purple,  2, 3, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Celo", EnumBlockchainType::Yellow,  2, 3, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Cosmos", EnumBlockchainType::Blue, 1, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Dogecoin", EnumBlockchainType::Gold, 1, 2, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Ethereum", EnumBlockchainType::DarkBlue, 3, 4, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Fantom", EnumBlockchainType::LightBlue, 1, 2, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Gnosis Chain", EnumBlockchainType::Green, 1, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Kava", EnumBlockchainType::Red, 2, 4, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Linea", EnumBlockchainType::Grey, 1, 2, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Metis", EnumBlockchainType::LightBlue, 1, 2, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Near", EnumBlockchainType::Green, 1, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Optimism", EnumBlockchainType::Red, 2, 4, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Osmosis", EnumBlockchainType::Pink, 1, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Polkadot", EnumBlockchainType::Pink, 1, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Polygon", EnumBlockchainType::Purple, 2, 3, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Scroll", EnumBlockchainType::Yellow, 2, 3, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Solana", EnumBlockchainType::Purple,  2, 3, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Starknet", EnumBlockchainType::DarkBlue, 3, 4, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Taiko", EnumBlockchainType::Pink, 1, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "Ton", EnumBlockchainType::Blue, 1, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new(Option::Some(world.contract_address), "ZKSync", EnumBlockchainType::Grey, 1, 2, 1))
        ];

       let dealer: ComponentDealer = IDealer::new(world.contract_address, cards_in_order);

       // Step 2: Register all these cards initially in the world for dealer as the owner.
       let mut index: usize = 0;
       while index < dealer.m_cards.len() {
           // Register the card's new owner.
           set!(world, (ICard::new(world.contract_address, dealer.m_cards.at(index).clone())));
           index += 1;
       };

       set!(world, (dealer));
    }

    fn distribute_cards(ref world: IWorldDispatcher, ref players: Array<ContractAddress>,
            ref cards: Array<EnumCard>) -> () {
        if players.is_empty() {
            panic!("There are no players to distribute cards to!");
        }

        while let Option::Some(player) = players.pop_front() {
            if cards.is_empty()  {
                break;
            }

            let mut player_hand = get!(world, (player), (ComponentHand));

            let mut index: usize = 0;
            while index < 5 {
                if let Option::Some(card_given) = cards.pop_front() {
                    player_hand.add(card_given);
                }
                index += 1;
            };

            set!(world, (player_hand));
        };
    }

    fn is_owner(world: @IWorldDispatcher, card: @EnumCard, caller: @ContractAddress) -> bool {
        let card_component = get!(*world, (*caller), (ComponentCard));
        if card.get_owner().is_none() {
            return false;
        }

        return card.get_owner().unwrap() == @card_component.m_ent_owner;
    }

    fn register_card(ref world: IWorldDispatcher, card: EnumCard, owner: ContractAddress) -> () {
        // Register the card's new owner.
        set!(world, (ICard::new(owner, card)));
    }

    fn discard_card(ref world: IWorldDispatcher, card: EnumCard) -> () {
        // Register the card's new owner.
        set!(world, (ICard::new(starknet::contract_address_const::<0x0>(), card)));
    }
}
