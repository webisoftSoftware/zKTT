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
    use starknet::{ContractAddress, get_block_timestamp, get_tx_info, get_caller_address};
    use zktt::models::components::{ComponentDealer, ComponentDeck, ComponentDeposit,
     ComponentHand, ComponentGame, ComponentPlayer, EnumGameState, EnumMoveError,
      EnumCard, EnumBlockchainType, EnumPlayerTarget, EnumGasFeeType,
       IBlockchain, IDeck, IDealer, IEnumCard, IGame, IGasFee, IDeposit, IPlayer, IHand, IAsset,
       StructAsset};
    use core::poseidon::poseidon_hash_span;

    //////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// INTERNAL /////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////

    /// Create the initial deck of cards for the game in a deterministic manner to then shuffle.
    ///
    /// Inputs:
    /// *world*: The mutable reference of the world to write components to.
    ///
    /// Output:
    /// The deck with one copy of all the card types (unflatten) [59].
    /// Can Panic?: no
    fn _create_cards(ref world: IWorldDispatcher) -> Array<EnumCard> nopanic {
        // Step 1: Create cards and put them in a container in order.
       let cards_in_order: Array<EnumCard> =
       // Eth.
       array![EnumCard::Asset(IAsset::new("ETH [1]", 1, 6)),
       EnumCard::Asset(IAsset::new("ETH [2]", 2, 5)),
       EnumCard::Asset(IAsset::new("ETH [3]", 3, 3)),
       EnumCard::Asset(IAsset::new("ETH [4]", 4, 3)),
       EnumCard::Asset(IAsset::new("ETH [5]", 5, 2)),
       EnumCard::Asset(IAsset::new("ETH [10]", 10, 1)),

       // Blockchains.
       EnumCard::Blockchain(IBlockchain::new("Aptos", EnumBlockchainType::Grey, 1, 2)),
       EnumCard::Blockchain(IBlockchain::new("Arbitrum", EnumBlockchainType::LightBlue, 1, 2)),
       EnumCard::Blockchain(IBlockchain::new("Avalanche", EnumBlockchainType::Red, 2, 4)),
       EnumCard::Blockchain(IBlockchain::new("Base", EnumBlockchainType::LightBlue, 1, 2)),
       EnumCard::Blockchain(IBlockchain::new("Bitcoin", EnumBlockchainType::Gold, 1, 2)),
       EnumCard::Blockchain(IBlockchain::new("Blast", EnumBlockchainType::Yellow,  2, 3)),
       EnumCard::Blockchain(IBlockchain::new("Canto", EnumBlockchainType::Green, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new("Celestia", EnumBlockchainType::Purple,  2, 3)),
       EnumCard::Blockchain(IBlockchain::new("Celo", EnumBlockchainType::Yellow,  2, 3)),
       EnumCard::Blockchain(IBlockchain::new("Cosmos", EnumBlockchainType::Blue, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new("Dogecoin", EnumBlockchainType::Gold, 1, 2)),
       EnumCard::Blockchain(IBlockchain::new("Ethereum", EnumBlockchainType::DarkBlue, 3, 4)),
       EnumCard::Blockchain(IBlockchain::new("Fantom", EnumBlockchainType::LightBlue, 1, 2)),
       EnumCard::Blockchain(IBlockchain::new("Gnosis Chain", EnumBlockchainType::Green, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new("Kava", EnumBlockchainType::Red, 2, 4)),
       EnumCard::Blockchain(IBlockchain::new("Linea", EnumBlockchainType::Grey, 1, 2)),
       EnumCard::Blockchain(IBlockchain::new("Metis", EnumBlockchainType::LightBlue, 1, 2)),
       EnumCard::Blockchain(IBlockchain::new("Near", EnumBlockchainType::Green, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new("Optimism", EnumBlockchainType::Red, 2, 4)),
       EnumCard::Blockchain(IBlockchain::new("Osmosis", EnumBlockchainType::Pink, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new("Polkadot", EnumBlockchainType::Pink, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new("Polygon", EnumBlockchainType::Purple, 2, 3)),
       EnumCard::Blockchain(IBlockchain::new("Scroll", EnumBlockchainType::Yellow, 2, 3)),
       EnumCard::Blockchain(IBlockchain::new("Solana", EnumBlockchainType::Purple,  2, 3)),
       EnumCard::Blockchain(IBlockchain::new("Starknet", EnumBlockchainType::DarkBlue, 3, 4)),
       EnumCard::Blockchain(IBlockchain::new("Taiko", EnumBlockchainType::Pink, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new("Ton", EnumBlockchainType::Blue, 1, 1)),
       EnumCard::Blockchain(IBlockchain::new("ZKSync", EnumBlockchainType::Grey, 1, 2)),

       // Actions.
       // EnumCard::PriorityFee(IPriorityFee::new(1, 10)),
       // EnumCard::ClaimYield(IClaimYield::new(2, 3)),
       // EnumCard::MajorityAttack(IMajorityAttack::new(Option::None, Option::None, 5, 1)),
       // EnumCard::FrontRun(IFrontRun::new(Option::None, Option::None, 3, 3)),
       EnumCard::GasFee(IGasFee::new(EnumPlayerTarget::All, EnumGasFeeType::AgainstTwo((EnumBlockchainType::DarkBlue,
                                    EnumBlockchainType::Red)), array![], 1, 2)),
       EnumCard::GasFee(IGasFee::new(EnumPlayerTarget::All, EnumGasFeeType::AgainstTwo((EnumBlockchainType::Yellow,
                                    EnumBlockchainType::Purple)), array![], 1, 2)),
       EnumCard::GasFee(IGasFee::new(EnumPlayerTarget::All, EnumGasFeeType::AgainstTwo((EnumBlockchainType::Green,
                                    EnumBlockchainType::LightBlue)), array![], 1, 2)),
       EnumCard::GasFee(IGasFee::new(EnumPlayerTarget::All, EnumGasFeeType::AgainstTwo((EnumBlockchainType::Grey,
                                    EnumBlockchainType::Pink)), array![], 1, 2)),
       EnumCard::GasFee(IGasFee::new(EnumPlayerTarget::All, EnumGasFeeType::AgainstTwo((EnumBlockchainType::Blue,
                                    EnumBlockchainType::Gold)), array![], 1, 2)),
       EnumCard::GasFee(IGasFee::new(EnumPlayerTarget::None, EnumGasFeeType::Any(EnumBlockchainType::Blue),
                                    array![], 3, 3)),
       // EnumCard::ReplayAttack(IReplayAttack::new(1, 2)),
       // EnumCard::ChainReorg(IChainReorg::new(3, 3)),
       // EnumCard::HardFork(IHardFork::new(3, 3)),
       // EnumCard::SoftFork(ISoftFork::new(3, 3)),
       // EnumCard::MEVBoost(IMEVBoost::new(3, 3)),
        ];

        return cards_in_order;
    }



    /// Flatten all copies of blockchains, Assets, and Action Cards in one big array for the dealer.
    ///
    /// Inputs:
    /// *container*: The deck with one copy of all the card types (unflatten) [59].
    ///
    /// Output:
    /// The deck with all copies of all the card types (flattened) [105].
    /// Can Panic?: yes
    fn _flatten(mut container: Array<EnumCard>) -> Array<EnumCard> {
        let mut flattened_array = ArrayTrait::new();

        while let Option::Some(mut card) = container.pop_front() {
            let mut index_left: u8 = card.get_index();
            while index_left > 0 {
                flattened_array.append(card.remove_one_index());
                index_left -= 1;
            };
        };
        return flattened_array;
    }

    /// Create the initial deck of cards for the game and assign them to the dealer. Only ran once
    /// when the contract deploys (sort of acting as a singleton).
    ///
    /// Inputs:
    /// *world*: The mutable reference of the world to write components to.
    ///
    /// Output:
    /// None.
    /// Can Panic?: yes
    fn dojo_init(ref world: IWorldDispatcher) {
       // Step 1: Create cards and put them in a container in order.
       let mut world_ref = world;
       let cards_in_order = _create_cards(ref world_ref);

       let dealer: ComponentDealer = IDealer::new(world.contract_address, cards_in_order);
       set!(world, (dealer));
    }

    /// Create the seed to provide to the randomizer for shuffling cards in the deck at the beginning
    /// of the game. The seed is meant to be a deterministic ranzomized hash, in the event that the
    /// game needs to be inspected and verified for proof.
    ///
    /// Inputs:
    /// *world*: The mutable reference of the world to write components to.
    /// *players: The array of all the players that have joined in the world.
    ///
    /// Output:
    /// The resulting seed hash.
    /// Can Panic?: yes
    fn _generate_seed(world_address: @ContractAddress, players: @Array<ContractAddress>) -> felt252 {
        let mut array_of_felts: Array<felt252> = array![get_block_timestamp().into(), get_tx_info().nonce];

        let mut index: usize = 0;
        while index < players.len() {
            array_of_felts.append(starknet::contract_address_to_felt252(*players.at(index)));
            index += 1;
        };

        let mut seed: felt252 = poseidon_hash_span(array_of_felts.span());
        return seed;
    }

    /// Take cards from the dealer's deck and distribute them across all players at the table.
    /// Five cards per player.
    ///
    /// Inputs:
    /// *world*: The mutable reference of the world to write components to.
    /// *players: The mutable reference of all the players that have joined in the world.
    /// *cards*: The dealer's cards to take cards from.
    ///
    /// Output:
    /// None.
    /// Can Panic?: yes
    fn _distribute_cards(ref world: IWorldDispatcher, ref players: Array<ContractAddress>,
            ref cards: Array<EnumCard>) -> () {
        if players.is_empty() {
            panic!("There are no players to distribute cards to!");
        }
        let mut index = 0;

        while let Option::Some(player) = players.get(index) {
            if cards.is_empty()  {
                break;
            }

            let mut player_hand = get!(world, (player.unbox().clone()), (ComponentHand));

            let mut inner_index: usize = 0;
            while inner_index < 5 {
                if let Option::Some(card_given) = cards.pop_front() {
                    player_hand.add(card_given);
                }
                inner_index += 1;
            };

            index += 1;
            set!(world, (player_hand));
        };
    }

    /// Take card from player's hand and put it in the discard pile after applying it's action.
    /// Once a card has been played, it cannot be retrieved back from the discard pile.
    ///
    /// Inputs:
    /// *world*: The mutable reference of the world to write components to.
    /// *caller: The player requesting to use the card.
    /// *card*: The card being played.
    ///
    /// Output:
    /// None.
    /// Can Panic?: yes
    fn _use_card(ref world: IWorldDispatcher, caller: @ContractAddress, card: EnumCard) -> () {
        let (mut hand, mut deck, mut deposit) = get!(world, (*caller), (ComponentHand, ComponentDeck, ComponentDeposit));
        assert!(hand.contains(@card.get_name()).is_some(), "Card not in player's hand");
        hand.remove(@card.get_name());

        match @card {
            EnumCard::Asset(asset) => {
                deposit.add(EnumCard::Asset(asset.clone()));
                set!(world, (deposit));
            },
            EnumCard::Blockchain(blockchain_struct) => {
                deck.add(EnumCard::Blockchain(blockchain_struct.clone()));
                set!(world, (deck));
            },
            EnumCard::ChainReorg(chain_reorg_struct) => {
                deck.add(EnumCard::ChainReorg(chain_reorg_struct.clone()));
                set!(world, (deck));
            },
            EnumCard::ClaimYield(_claim_yield_struct) => {},
            EnumCard::GasFee(gas_fee_struct) => {
                assert!(gas_fee_struct.m_color_chosen.is_some(), "Invalid Gas Fee move: No color specified");
                match gas_fee_struct.m_blockchain_type_affected {
                    EnumGasFeeType::Any(color) =>  {
                        if color != @(*gas_fee_struct.m_color_chosen).unwrap() {
                            panic!("Invalid Gas Fee move: Color does not match allowed colors");
                        }
                    },
                    EnumGasFeeType::AgainstTwo((color1, color2)) => {
                        if color1 != @(*gas_fee_struct.m_color_chosen).unwrap() && color2 !=
                            @(*gas_fee_struct.m_color_chosen).unwrap() {
                            panic!("Invalid Gas Fee move: Color does not match allowed colors");
                        }
                    }
                };

                let fee: u8 = gas_fee_struct.get_fee();

                // Make every affected player in debt for their next turn.
                match gas_fee_struct.m_players_affected {
                    EnumPlayerTarget::All(_) => {
                        let mut index = 0;
                        let game = get!(world, (world.contract_address), (ComponentGame));

                        while index < game.m_players.len() {
                            let mut player_component = get!(world, (*game.m_players.at(index)), (ComponentPlayer));
                            player_component.m_in_debt = Option::Some(fee);
                            set!(world, (player_component));
                            index += 1;
                        };
                    },
                    EnumPlayerTarget::One(player) => {
                        let mut player_component = get!(world, (*player), (ComponentPlayer));
                        player_component.m_in_debt = Option::Some(fee);
                        set!(world, (player_component));
                    },
                    _ => panic!("Invalid Gas Fee move: No players targeted")
                };
            },
            EnumCard::HardFork(_hardfork_struct) => {

                //let mut discard_pile = get!(world, (world.contract_address), (ComponentDiscardPile));
                //let last_card = discard_pile.m_cards.at(discard_pile.m_cards.len() - 1);

                // Revert last move for this player.
                //let revert_action = last_card.revert();
            },
            EnumCard::MEVBoost(mev_boost_struct) => {
                deck.add(EnumCard::MEVBoost(mev_boost_struct.clone()));
                set!(world, (deck));
            },
            EnumCard::PriorityFee(_priority_fee_struct) => {
                 let mut dealer = get!(world, (world.contract_address), (ComponentDealer));
                 assert!(!dealer.m_cards.is_empty(), "Dealer has no more cards");

                 hand.add(dealer.pop_card().unwrap());
                 hand.add(dealer.pop_card().unwrap());
                 set!(world, (hand, dealer));
            },
            EnumCard::ReplayAttack(_replay_attack_struct) => {},
            EnumCard::SoftFork(soft_fork_struct) => {
                deck.add(EnumCard::SoftFork(soft_fork_struct.clone()));
                set!(world, (deck));
            },
            EnumCard::FrontRun(frontrun_struct) => {
                let bc_owner = _get_owner(@world, frontrun_struct.m_blockchain_name);
                assert!(bc_owner.is_some(), "Blockchain in Frontrun card has no owner");

                let mut opponent_deck = get!(world, (bc_owner.unwrap()), (ComponentDeck));
                if let Option::Some(card_index) = opponent_deck.contains(frontrun_struct.m_blockchain_name) {
                    deck.add(opponent_deck.m_cards.at(card_index).clone());
                    opponent_deck.remove(frontrun_struct.m_blockchain_name);
                    set!(world, (deck, opponent_deck));
                } else {
                    panic!("Invalid FrontRun move: Opponent Blockchain not found");
                }
            },
            EnumCard::MajorityAttack(asset_group_struct) => {
                let mut opponent_deck = get!(world, (*asset_group_struct.m_owner), (ComponentDeck));
                let mut player = get!(world, (*caller), (ComponentPlayer));
                let mut opponent_player = get!(world, (*asset_group_struct.m_owner), (ComponentPlayer));

                player.m_sets += 1;
                opponent_player.m_sets -= 1;

                let mut index: usize = 0;
                while let Option::Some(bc_name) = asset_group_struct.m_set.get(index) {
                    if let Option::Some(blockchain_index) = opponent_deck.contains(bc_name.unbox()) {
                        deck.add(opponent_deck.m_cards.at(blockchain_index).clone());
                        opponent_deck.remove(bc_name.unbox());
                    }
                    index += 1;
                };
                set!(world, (deck, opponent_deck, player, opponent_player));
            },
            _ => panic!("Invalid or illegal move!")
        };

        return ();
    }

    /// Check to see if the caller has the right to play or move around a card.
    ///
    /// Inputs:
    /// *world*: The immutable reference of the world to retrieve components from.
    /// *caller: The player requesting to use or move the card.
    /// *card*: The immutable reference to the card in question.
    ///
    /// Output:
    /// None.
    /// Can Panic?: yes
    fn _is_owner(world: @IWorldDispatcher, card_name: @ByteArray, caller: @ContractAddress) -> bool {
        let (hand, deck, deposit) = get!(*world, (*caller), (ComponentHand, ComponentDeck, ComponentDeposit));
        return hand.contains(card_name).is_some() || deck.contains(card_name).is_some() ||
            deposit.contains(card_name).is_some();
    }

    fn _get_owner(world: @IWorldDispatcher, card_name: @ByteArray) -> Option<ContractAddress> {
        let game = get!(*world, (*world.contract_address), (ComponentGame));
        assert!(game.m_state == EnumGameState::Started, "Game has not started yet");

        let mut index = 0;
        let mut owner = Option::None;

        while index < game.m_players.len() {
            let (hand, deck, deposit) = get!(*world, (*game.m_players.at(index)),
                (ComponentHand, ComponentDeck, ComponentDeposit));

            if let Option::Some(_) = hand.contains(card_name) {
                owner = Option::Some(*game.m_players.at(index));
                break;
            }

            if let Option::Some(_) = deck.contains(card_name) {
                owner = Option::Some(*game.m_players.at(index));
                break;
            }

            if let Option::Some(_) = deposit.contains(card_name) {
                owner = Option::Some(*game.m_players.at(index));
                break;
            }

            index += 1;
        };

        return owner;
    }

    //////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////
    /////////////////////////////// PUBLIC ///////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////////////////


    /// Public contract deployed on chain, representing our 'table' in the card game for that specific
    /// world.
    #[abi(embed_v0)]
    impl ITableImpl of ITable<ContractState> {

        /// Allows a player to join the table deployed, as long as the game hasn't started/ended yet.
        ///
        /// Inputs:
        /// *world*: The mutable reference of the world to write components to.
        /// *username*: The user-selected displayed name identifyinh the current player's name.
        /// Note that the current implementation allows for multiple users to have the same username.
        ///
        /// Output:
        /// None.
        /// Can Panic?: yes
        fn join(ref world: IWorldDispatcher, username: ByteArray) -> () {
            let mut game = get!(world, (world.contract_address), (ComponentGame));
            assert!(game.m_state != EnumGameState::Started, "Game has already started");
            assert!(game.m_players.len() < 5, "Lobby already full");

            let caller = get_caller_address();

            // Initialize players with three moves.
            let player = IPlayer::new(caller, username);
            game.add_player(caller);
            set!(world, (game, player));
            return ();
        }

        /// Starts the game and denies any new players from joining, as long as there are at
        /// least two players that have joined for up to a maximum of 5 players.
        ///
        /// Inputs:
        /// *world*: The mutable reference of the world to write components to.
        ///
        /// Output:
        /// None.
        /// Can Panic?: yes
        fn start(ref world: IWorldDispatcher) -> () {
            let seed = world.contract_address;
            let mut game: ComponentGame = get!(world, (seed), (ComponentGame));

            assert!(game.m_state != EnumGameState::Started, "Game has already started");
            assert!(game.m_players.len() >= 2, "Missing at least a player before starting");

            game.m_state = EnumGameState::Started;

            // Step 2: Create another container with shuffled cards using seed and pseudo-random algorithm.
            let seed: felt252 = _generate_seed(@world.contract_address, @game.m_players);
            let mut dealer = get!(world, (world.contract_address), (ComponentDealer));
            dealer.shuffle(seed);

            // Step 3: Distribute 5 cards per player by drawing from the dealer's deck.
            let mut world_ref = world;
            _distribute_cards(ref world_ref, ref game.m_players, ref dealer.m_cards);

            // Step 4: Assign the first turn (clockwise of players joined [FIFO]).
            game.assign_next_turn(true);
            set!(world, (dealer, game));
            return ();
        }

        /// Adds two new cards from the dealer's deck to the active caller's hand, during their turn.
        /// This can only happen once per turn, at the beginning of it (first move).
        ///
        /// Inputs:
        /// *world*: The mutable reference of the world to write components to.
        /// *draws_five*: Flag indicating if the active caller can draw five cards from the deck
        /// instead of the typical two. This behavior can only happend if the player has no more
        /// cards left in their hand at the end of their last turn.
        ///
        /// Output:
        /// None.
        /// Can Panic?: yes
        fn draw(ref world: IWorldDispatcher, draws_five: bool) -> () {
            let caller = get_caller_address();
            let (mut hand, mut player) = get!(world, (caller), (ComponentHand, ComponentPlayer));
            let game = get!(world, (world.contract_address), (ComponentGame));

            assert!(game.m_state == EnumGameState::Started, "Game has not started yet");
            assert!(game.m_player_in_turn == caller, "Not player's turn");
            assert!(!player.m_has_drawn, "Cannot draw mid-turn");

            let mut dealer = get!(world, (world.contract_address), ComponentDealer);
            if draws_five {
                assert!(hand.m_cards.len() == 0, "Cannot draw five, hand not empty");
                let mut index: usize = 0;

                while index < 5 {
                    if dealer.m_cards.is_empty() {
                        panic!("Dealer has no more cards");
                    }

                    let card = dealer.pop_card().unwrap();
                    hand.add(card);
                };

                player.m_has_drawn = true;
                set!(world, (hand, dealer, player));
                return ();
            }

            let mut dealer = get!(world, (world.contract_address), ComponentDealer);
            let card1_opt = dealer.pop_card();
            let card2_opt = dealer.pop_card();

            if card1_opt.is_none() || card2_opt.is_none() {
                panic!("Deck does not have any more cards!");
            }

            // Draw two cards.
            hand.add(card1_opt.unwrap());
            hand.add(card2_opt.unwrap());
            player.m_has_drawn = true;
            set!(world, (hand, dealer, player));
        }

        /// Adds two new cards from the dealer's deck to the active caller's hand, during their turn.
        /// This can only happen once per turn, at the beginning of it (first move).
        ///
        /// Inputs:
        /// *world*: The mutable reference of the world to write components to.
        /// *draws_five*: Flag indicating if the active caller can draw five cards from the deck
        /// instead of the typical two. This behavior can only happend if the player has no more
        /// cards left in their hand at the end of their last turn.
        ///
        /// Output:
        /// None.
        /// Can Panic?: yes
        fn play(ref world: IWorldDispatcher, card: EnumCard) -> () {
            let game = get!(world, (world.contract_address), (ComponentGame));
            assert!(game.m_state == EnumGameState::Started, "Game has not started yet");
            assert!(game.m_player_in_turn == get_caller_address(), "Not player's turn");

            let caller = get_caller_address();
            let mut player = get!(world, caller, (ComponentPlayer));
            assert!(player.m_has_drawn, "Player needs to draw cards first");
            assert!(player.m_moves_remaining != 0, "No moves left");

            let mut world_cpy = world;
            assert!(_is_owner(@world_cpy, @card.get_name(), @caller), "Player does not own card");
            _use_card(ref world_cpy, @caller, card);

            player.m_moves_remaining -= 1;
            set!(world, (player));
            return ();
        }

        /// Move around cards in the caller's deck, without it counting as a move. Can only happen
        /// during the caller's turn. This system is for when a player wants to stack/unstack
        /// blockchains together to form/break asset groups, depending on their strategy.
        /// As expected, only matching colors can be stacked on top of each other (or immutable card).
        ///
        /// Inputs:
        /// *world*: The mutable reference of the world to write components to.
        /// *card*: Card to move.
        ///
        /// Output:
        /// None.
        /// Can Panic?: yes
        fn move(ref world: IWorldDispatcher, card: EnumCard) -> () {
            let game = get!(world, (world.contract_address), (ComponentGame));
            assert!(game.m_state == EnumGameState::Started, "Game has not started yet");
            assert!(game.m_player_in_turn == get_caller_address(), "Not player's turn");

            let caller = get_caller_address();
            let mut player = get!(world, caller, (ComponentPlayer));
            assert!(player.m_has_drawn, "Player needs to draw cards first");

            let mut world_cpy = world;
            assert!(_is_owner(@world_cpy, @card.get_name(), @caller), "Player does not own card");
            // TODO: Move card around in deck.
            set!(world, (player));
            return ();
        }

        /// Make the caller pay the recipient the amount owed. This happens when the recipient plays
        /// the 'Claim' action card beforehand and targets this caller with it. Once the recipient's
        /// turn is over, the payee(s) will have a status of 'InDebt' which will prompt them to pay
        /// the fees upon their turn (unless 'HardFork' is played). The payee(s) cannot initiate
        /// turns until the amount owed has been payed, either partially (if they do not have
        /// enough funds) or fully.
        ///
        /// Inputs:
        /// *world*: The mutable reference of the world to write components to.
        /// *card*: Card to move.
        ///
        /// Output:
        /// None.
        /// Can Panic?: yes
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
                    payee_stash.remove(@card.get_name());
                    recipient_stash.add(card);
                    continue;
                }

                // Give blockchains as payment.
                payee_deck.remove(@card.get_name());
                recipient_deck.add(card);
            };

            // Remove player's debt.
            player.m_in_debt = Option::None;
            set!(world, (recipient_stash, recipient_deck, payee_stash, payee_deck, player));
        }

        /// Signal the end of a turn for the caller. This renders all other moves forbidden until
        /// next turn.
        ///
        /// Inputs:
        /// *world*: The mutable reference of the world to write components to.
        ///
        /// Output:
        /// None.
        /// Can Panic?: yes
        fn end_turn(ref world: IWorldDispatcher) -> () {
            let mut game = get!(world, (world.contract_address), (ComponentGame));
            assert!(game.m_state == EnumGameState::Started, "Game has not started yet");
            assert!(game.m_player_in_turn == get_caller_address(), "Not player's turn");

            game.assign_next_turn(false);
            set!(world, (game));
            return ();
        }

        /// Make the caller's player leave the table and surrender all cards to the discard pile.
        ///
        /// Inputs:
        /// *world*: The mutable reference of the world to write components to.
        ///
        /// Output:
        /// None.
        /// Can Panic?: yes
        fn leave(ref world: IWorldDispatcher) -> () {
            let mut game = get!(world, (world.contract_address), (ComponentGame));
            assert!(game.m_state == EnumGameState::Started, "Game has not started yet");
            assert!(game.contains_player(@get_caller_address()).is_some(), "Player not found");

            let (mut hand, mut deck, mut deposit) = get!(world, (get_caller_address()), (ComponentHand,
            ComponentDeck, ComponentDeposit));

            // TODO: Cleanup after player by setting all card owner's to 0.
            // hand.discard_cards();
            // deck.discard_cards();
            // deposit.discard_cards();

            game.remove_player(@get_caller_address());
            delete!(world, (hand, deck, deposit));
            set!(world, (game));
            return ();
        }
    }
}
