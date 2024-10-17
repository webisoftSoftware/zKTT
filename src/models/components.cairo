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

use starknet::ContractAddress;
// use origami_random::deck::{Deck, DeckTrait};
use core::fmt::{Display, Formatter, Error};
use debug::PrintTrait;
use cartridge_vrf::IVrfProviderDispatcher;
use cartridge_vrf::IVrfProviderDispatcherTrait;
use cartridge_vrf::Source;

////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////// COMPONENTS /////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

const VRF_PROVIDER_ADDRESS: felt252 = 0x051fea4450da9d6aee758bdeba88b2f665bcbf549d2c61421aa724e9ac0ced8f;

/// Component that represents the Pile of cards in the middle of the board, not owned by any player
/// yet.
///
/// Per table.
#[derive(Drop, Serde, Clone, Debug)]
#[dojo::model]
struct ComponentDealer {
    #[key]
    m_ent_owner: ContractAddress,
    m_cards: Array<EnumCard>
}

/// Component that represents the deck containing all blockchains not in the player's hand.
///
/// Per player.
#[derive(Drop, Serde, Clone, Debug)]
#[dojo::model]
struct ComponentDeck {
    #[key]
    m_ent_owner: ContractAddress,
    m_cards: Array<EnumCard>,
}

/// Component that represents the pile of assets that each player owns in the game.
///
/// Per player.
#[derive(Drop, Serde, Clone, Debug)]
#[dojo::model]
struct ComponentDeposit {
    #[key]
    m_ent_owner: ContractAddress,
    m_cards: Array<EnumCard>,
    m_total_value: u8
}

/// Component that represents the game state and acts as storage to keep track of the number of
/// players currently at the table.
///
/// Per table.
#[derive(Drop, Serde)]
#[dojo::model]
struct ComponentGame {
    #[key]
    m_ent_seed: felt252,
    m_state: EnumGameState,
    m_players: Array<ContractAddress>,
    m_player_in_turn: ContractAddress
}

/// Component that represents the cards held in hand of a player in the game.
///
/// Per player.
#[derive(Drop, Serde, Clone, Debug)]
#[dojo::model]
struct ComponentHand {
    #[key]
    m_ent_owner: ContractAddress,
    m_cards: Array<EnumCard>,
}

/// Component that represents a player in the game. Note that the username is not unique, only the
/// address is.
///
/// Per player.
#[derive(Drop, Serde, Clone, Debug)]
#[dojo::model]
struct ComponentPlayer {
    #[key]
    m_ent_owner: ContractAddress,
    m_username: ByteArray,
    m_moves_remaining: u8,
    m_score: u32,
    m_sets: u8,
    m_has_drawn: bool,
    m_in_debt: Option<u8>
}

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////// STRUCTS /////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

/// Card containing the info about an asset (card that only has monetary value).
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct StructAsset {
    m_name: ByteArray,
    m_value: u8,
    m_index: u8
}

/// Card containing the info about a specific asset group (set of matching blockchains).
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct StructAssetGroup {
    m_set: Array<StructBlockchain>,
    m_total_fee_value: u8
}

/// Card containing the info about a specific blockchain.
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct StructBlockchain {
    m_name: ByteArray,
    m_bc_type: EnumBlockchainType,
    m_fee: u8,
    m_value: u8
}

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////// ACTIONS /////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

/// Swap a single blockchain with a player.
///
/// Fields:
/// *m_self_blockchain_name*: The name of the blockchain from the caller to be swapped.
/// *m_opponent_blockchain_name*: The name of the blockchain to look up from the opponent to be
/// swapped.
/// *m_value*: Value of the card itself, in case we want to give it as eth.
/// *m_index*: The card index from all of its duplicates in the deck.
#[derive(Drop, Serde, Clone, Introspect, PartialEq, Debug)]
struct ActionChainReorg {
    m_self_blockchain_name: ByteArray,
    m_opponent_blockchain_name: ByteArray,
    m_value: u8,
    m_index: u8
}

/// All other players pay you 2 ETH.
///
/// Fields:
/// *m_value*: Value of the card itself, in case we want to give it as eth.
/// *m_index*: The card index from all of its duplicates in the deck.
#[derive(Drop, Serde, Clone, Introspect, PartialEq, Debug)]
struct ActionClaimYield {
    m_value: u8,
    m_index: u8
}

/// Card that allows a player to steal a blockchain from another player's deck.
///
/// Fields:
/// *m_blockchain_name*: Name of the card to be stolen.
/// *m_value*: Value of the card itself, in case we want to give it as eth.
/// *m_index*: The card index from all of its duplicates in the deck.
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct ActionFrontrun {
    m_blockchain_name: ByteArray,
    m_value: u8,
    m_index: u8
}

/// One player pays a gas fee for each blockchain you own in a selected color.
/// OR
/// Every player pays a gas fee for each blockchain you own in either color.
///
/// Fields:
/// *m_players_affected*: Enum indicating who is the target(s) of this action (owing).
/// *m_blockchain_type_affected*: Enum Specifying what type of gas fee this action is.
///   If the action is targeted at everyone, one of two colors can be used.
///   If the action targets only one opponent, only one color can be used.
/// *m_count*: How the fee will be calculated depnding on how many cards of the same color.
/// *m_value*: Value of the card itself, in case we want to give it as eth.
/// *m_index*: The card index from all of its duplicates in the deck.
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct ActionGasFee {
    m_players_affected: EnumPlayerTarget,
    // First blockchain (target one player), second blockchain (Target all players).
    m_blockchain_type_affected: EnumGasFeeType,
    m_set_applied: Array<StructBlockchain>,
    m_color_chosen: Option<EnumBlockchainType>,
    m_value: u8,
    m_index: u8
}

/// Useable within 10 seconds of certain Onchain Events - cancels other players Onchain Event card.
///
/// Fields:
/// *m_value*: Value of the card itself, in case we want to give it as eth.
/// *m_index*: The card index from all of its duplicates in the deck.
#[derive(Drop, Serde, Clone, Introspect, PartialEq, Debug)]
struct ActionHardFork {
    m_value: u8,
    m_index: u8
}

/// Add onto any full blockchain set owned to add 3 ETH to value.
///
/// Fields:
/// *m_full_set*: A array of blockchain names, pointing to which blockchains should this apply for.
/// *m_value*: Value of the card itself, in case we want to give it as eth.
/// *m_index*: The card index from all of its duplicates in the deck.
#[derive(Drop, Serde, Clone, Introspect, PartialEq, Debug)]
struct ActionMEVBoost {
    m_full_set: Array<ByteArray>,
    m_value: u8,
    m_index: u8
}

/// Steal an asset group from an opponent.
///
/// Fields:
/// *m_full_set*: A array of blockchain names, pointing to which blockchains should this apply for.
/// *m_value*: Value of the card itself, in case we want to give it as eth.
/// *m_index*: The card index from all of its duplicates in the deck.
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct ActionMajorityAttack {
    m_owner: ContractAddress,
    m_set: Array<ByteArray>,
    m_value: u8,
    m_index: u8
}

/// Card that allows a player to draw two additional cards, and make it only count as one move.
///
/// Fields:
/// *m_value*: Value of the card itself, in case we want to give it as eth.
/// *m_index*: The card index from all of its duplicates in the deck.
#[derive(Drop, Serde, Clone, Introspect, PartialEq, Debug)]
struct ActionPriorityFee {
    m_value: u8,
    m_index: u8
}

/// Played before Gas Fee card, doubles amount of ETH paid to player.
///
/// Fields:
/// *m_value*: Value of the card itself, in case we want to give it as eth.
/// *m_index*: The card index from all of its duplicates in the deck.
#[derive(Drop, Serde, Clone, Introspect, PartialEq, Debug)]
struct ActionReplayAttack {
    m_value: u8,
    m_index: u8
}

/// Add onto any full blockchain set owned to add 4 ETH to value.
///
/// Fields:
/// *m_full_set*: A array of blockchain names, pointing to which blockchains should this apply for.
/// *m_value*: Value of the card itself, in case we want to give it as eth.
/// *m_index*: The card index from all of its duplicates in the deck.
#[derive(Drop, Serde, Clone, Introspect, PartialEq, Debug)]
struct ActionSoftFork {
    m_full_set: Array<ByteArray>,
    m_value: u8,
    m_index: u8
}

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////// DISPLAY /////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

impl ComponentDeckDisplay of Display<ComponentDeck> {
    fn fmt(self: @ComponentDeck, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("{0}'s Deck:", starknet::contract_address_to_felt252(*self.m_ent_owner));
        f.buffer.append(@str);

        let mut index: usize = 0;
        while index < self.m_cards.len() {
            let str: ByteArray = format!("\n\t\t{0}", self.m_cards.at(index));
            f.buffer.append(@str);
            index += 1;
        };

        return Result::Ok(());
    }
}

impl ComponentHandDisplay of Display<ComponentHand> {
    fn fmt(self: @ComponentHand, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("{0}'s Hand:", starknet::contract_address_to_felt252(*self.m_ent_owner));
        f.buffer.append(@str);

        let mut index: usize = 0;
        while index < self.m_cards.len() {
            let str: ByteArray = format!("\n\t\t{0}", self.m_cards.at(index));
            f.buffer.append(@str);
            index += 1;
        };

        return Result::Ok(());
    }
}

impl ComponentPlayerDisplay of Display<ComponentPlayer> {
    fn fmt(self: @ComponentPlayer, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Owner: {0}, Player: {1}, Asset Groups Owned: {2}, Moves remaining: {3}, Score: {4}",
         starknet::contract_address_to_felt252(*self.m_ent_owner), self.m_username, *self.m_sets,
          *self.m_moves_remaining, *self.m_score);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl StructAssetDisplay of Display<StructAsset> {
    fn fmt(self: @StructAsset, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Asset: {0}, Value: {1}, Index: {2}",
         self.m_name, *self.m_value, *self.m_index);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl StructBlockchainDisplay of Display<StructBlockchain> {
    fn fmt(self: @StructBlockchain, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Blockchain: {0}, Type: {1}, Fee: {2}, Value {3}",
         self.m_name, self.m_bc_type, *self.m_fee, *self.m_value);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl ActionChainReorgDisplay of Display<ActionChainReorg> {
    fn fmt(self: @ActionChainReorg, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Chain Reorg: Value {0}, Index {1}", *self.m_value,
        *self.m_index);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl ActionClaimYieldDisplay of Display<ActionClaimYield> {
    fn fmt(self: @ActionClaimYield, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Claim Yield: Value {0}, Index {1}", *self.m_value,
        *self.m_index);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl ActionFrontrunDisplay of Display<ActionFrontrun> {
    fn fmt(self: @ActionFrontrun, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Steal Blockchain: Blockchain: {0},
        Value {1}, Index: {2}", self.m_blockchain_name, *self.m_value, *self.m_index);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl ActionHardForkDisplay of Display<ActionHardFork> {
    fn fmt(self: @ActionHardFork, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Deny: Value {0}, Index {1}", *self.m_value,
        *self.m_index);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl ActionMEVBoostDisplay of Display<ActionMEVBoost> {
    fn fmt(self: @ActionMEVBoost, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("MEV Boost: Value {0}, Index {1}", *self.m_value,
        *self.m_index);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl ActionPriorityFeeDisplay of Display<ActionPriorityFee> {
    fn fmt(self: @ActionPriorityFee, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Draw Two Cards: Value {0}, Index {1}",
         *self.m_value, *self.m_index);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl ActionReplayAttackDisplay of Display<ActionReplayAttack> {
    fn fmt(self: @ActionReplayAttack, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Replay Attack: Value {0}, Index {1}", *self.m_value,
        *self.m_index);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl ActionSoftForkDisplay of Display<ActionSoftFork> {
    fn fmt(self: @ActionSoftFork, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Soft Fork: Value {0}, Index {1}", *self.m_value,
        *self.m_index);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl EnumCardDisplay of Display<EnumCard> {
    fn fmt(self: @EnumCard, ref f: Formatter) -> Result<(), Error> {
        match self {
            EnumCard::Asset(data) => {
                let str: ByteArray = format!("{data}");
                f.buffer.append(@str);
            },
            EnumCard::Blockchain(data) => {
                let str: ByteArray = format!("{data}");
                f.buffer.append(@str);
            },
            EnumCard::GasFee(data) => {
                let str: ByteArray = format!("{data}");
                f.buffer.append(@str);
            },
            EnumCard::HardFork(data) => {
                let str: ByteArray = format!("{data}");
                f.buffer.append(@str);
            },
            EnumCard::PriorityFee(data) => {
                let str: ByteArray = format!("{data}");
                f.buffer.append(@str);
            },
            EnumCard::FrontRun(data) => {
                let str: ByteArray = format!("{data}");
                f.buffer.append(@str);
            },
            EnumCard::MajorityAttack(data) => {
                let str: ByteArray = format!("{data}");
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
            EnumBlockchainType::Immutable(_) => {
                let str: ByteArray = format!("Immutable");
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
            EnumBlockchainType::Grey(_) => {
                let str: ByteArray = format!("Grey");
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
            EnumBlockchainType::Yellow(_) => {
                let str: ByteArray = format!("Yellow");
                f.buffer.append(@str);
            },
        };
        return Result::Ok(());
    }
}

impl EnumGasFeeTypeDisplay of Display<EnumGasFeeType> {
    fn fmt(self: @EnumGasFeeType, ref f: Formatter) -> Result<(), Error> {
        match self {
            EnumGasFeeType::Any(color) => {
                let str: ByteArray = format!("Against One: {0}", color);
                f.buffer.append(@str);
            },
            EnumGasFeeType::AgainstTwo((color1, color2)) => {
                let str: ByteArray = format!("Against Two: {0}, {1}", color1, color2);
                f.buffer.append(@str);
            }
        };

        return Result::Ok(());
    }
}

impl EnumMoveErrorDisplay of Display<EnumMoveError> {
    fn fmt(self: @EnumMoveError, ref f: Formatter) -> Result<(), Error> {
        match self {
            EnumMoveError::CardAlreadyPresent(_) => {
                let str: ByteArray = format!("Card Already Present!");
                f.buffer.append(@str);
            },
            EnumMoveError::CardNotFound(_) => {
                let str: ByteArray = format!("Card Not found!");
                f.buffer.append(@str);
            },
            EnumMoveError::NotEnoughMoves(_) => {
                let str: ByteArray = format!("Not Enough Moves to Proceed!");
                f.buffer.append(@str);
            },
            EnumMoveError::SetAlreadyPresent(_) => {
                let str: ByteArray = format!("asset Group Already Present!");
                f.buffer.append(@str);
            }
        };
        return Result::Ok(());
    }
}

impl ActionGasFeeDisplay of Display<ActionGasFee> {
    fn fmt(self: @ActionGasFee, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Gas Fee: Targeted Blockchain: {0}, Value {1}, Index {2}",
        self.m_blockchain_type_affected, *self.m_value, *self.m_index);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl ActionMajorityAttackDisplay of Display<ActionMajorityAttack> {
    fn fmt(self: @ActionMajorityAttack, ref f: Formatter) -> Result<(), Error> {
        let mut index = 0;
        while index < self.m_set.len() {
            if let Option::Some(bc) = self.m_set.get(index) {
                let str: ByteArray = format!("\nBlockchain: {0}", bc.unbox());
                f.buffer.append(@str);
            }
        };

        return Result::Ok(());
    }
}

///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////
/////////////////////////////// PARTIALEQ /////////////////////////////////
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

impl HandPartialEq of PartialEq<ComponentHand> {
    fn eq(lhs: @ComponentHand, rhs: @ComponentHand) -> bool {
        let mut index: usize = 0;
        if lhs.m_cards.len() != rhs.m_cards.len() {
            return false;
        }

        return loop {
            if index >= lhs.m_cards.len() {
                break true;
            }

            if lhs.m_cards.at(index) != rhs.m_cards.at(index) {
                break false;
            }
            index += 1;
        };
    }
}

impl StructAssetEq of PartialEq<StructAsset> {
    fn eq(lhs: @StructAsset, rhs: @StructAsset) -> bool {
        return lhs.m_name == rhs.m_name && lhs.m_index == rhs.m_index;
    }
}

impl StructAssetGroupEq of PartialEq<StructAssetGroup> {
    fn eq(lhs: @StructAssetGroup, rhs: @StructAssetGroup) -> bool {
        let mut index: usize = 0;
        return loop {
            if index >= lhs.m_set.len() {
                break true;
            }

            if lhs.m_set.at(index) != rhs.m_set.at(index) {
                break false;
            }
            index += 1;
        };
    }
}

impl StructBlockchainEq of PartialEq<StructBlockchain> {
    fn eq(lhs: @StructBlockchain, rhs: @StructBlockchain) -> bool {
        return lhs.m_name == rhs.m_name;
    }
}

impl ActionFrontrunEq of PartialEq<ActionFrontrun> {
    fn eq(lhs: @ActionFrontrun, rhs: @ActionFrontrun) -> bool {
        return lhs.m_index == rhs.m_index;
    }
}

impl ActionGasFeeEq of PartialEq<ActionGasFee> {
    fn eq(lhs: @ActionGasFee, rhs: @ActionGasFee) -> bool {
        return lhs.m_index == rhs.m_index;
    }
}

impl ActionMajorityAttackEq of PartialEq<ActionMajorityAttack> {
    fn eq(lhs: @ActionMajorityAttack, rhs: @ActionMajorityAttack) -> bool {
        let mut index: usize = 0;
        return loop {
            if index >= lhs.m_set.len() {
                break true;
            }

            if lhs.m_set.at(index) != rhs.m_set.at(index) {
                break false;
            }
            index += 1;
        };
    }
}

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
/////////////////////////////// INTO ///////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

impl EnumCardInto of Into<@EnumCard, ByteArray> {
    fn into(self: @EnumCard) -> ByteArray {
        return match self {
            EnumCard::Asset(asset_struct) => format!("{0}", asset_struct.m_name),
            EnumCard::Blockchain(bc_struct) => format!("{0}", bc_struct.m_name),
            EnumCard::ChainReorg(_) => "Chain Reorg",
            EnumCard::ClaimYield(_) => "Claim Yield",
            EnumCard::GasFee(_) => "Gas Fee",
            EnumCard::HardFork(_) => "Hardfork",
            EnumCard::MEVBoost(_) => "MEV Boost",
            EnumCard::PriorityFee(_) => "Priority Fee",
            EnumCard::ReplayAttack(_) => "Replay Attack",
            EnumCard::SoftFork(_) => "Soft Fork",
            EnumCard::FrontRun(_) => "Frontrun",
            EnumCard::MajorityAttack(_) => "51% Attack",
        };
    }
}


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
/////////////////////////////// TRAITS /////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

#[generate_trait]
impl StructAssetImpl of IAsset {
    fn new(name: ByteArray, value: u8, copies_left: u8) -> StructAsset nopanic {
        return StructAsset {
            m_name: name,
            m_value: value,
            m_index: copies_left
        };
    }
}

#[generate_trait]
impl StructAssetGroupImpl of IAssetGroup {
    fn new(blockchains: Array<StructBlockchain>, total_fee_value: u8) -> StructAssetGroup nopanic {
        return StructAssetGroup {
            m_set: blockchains,
            m_total_fee_value: total_fee_value
        };
    }
}

#[generate_trait]
impl StructBlockchainImpl of IBlockchain {
    fn new(name: ByteArray, bc_type: EnumBlockchainType, fee: u8, value: u8) -> StructBlockchain nopanic {
        return StructBlockchain {
            m_name: name,
            m_bc_type: bc_type,
            m_fee: fee,
            m_value: value
        };
    }
}

#[generate_trait]
impl StructPriorityFeeImpl of IDraw {
    fn new(value: u8, copies_left: u8) -> ActionPriorityFee nopanic {
        return ActionPriorityFee {
            m_value: value,
            m_index: copies_left
        };
    }
}

#[generate_trait]
impl DealerImpl of IDealer {
    fn new(owner: ContractAddress, cards: Array<EnumCard>) -> ComponentDealer nopanic {
        return ComponentDealer {
            m_ent_owner: owner,
            m_cards: cards
        };
    }

    fn shuffle(ref self: ComponentDealer, seed: felt252) -> () {
        let mut shuffled_cards: Array<EnumCard> = ArrayTrait::new();
        // let mut deck = DeckTrait::new(seed, self.m_cards.len());
        let vrf_provider = IVrfProviderDispatcher { contract_address:
            starknet::contract_address_const::<VRF_PROVIDER_ADDRESS>() };
        let mut random_value: u256 = vrf_provider.consume_random(Source::Salt(seed)).into();
        let mut max_number: u32 = self.m_cards.len() - 1;

        while max_number > 0 {
            // Draw a random number from 0 to 105.
            random_value = vrf_provider.consume_random(Source::Salt(seed)).into();
            let card_index: u8 = (random_value % max_number.into()).try_into().unwrap();

            if let Option::Some(_) = self.m_cards.get(card_index.into()) {
                shuffled_cards.append(self.m_cards[card_index.into()].clone());
                max_number -= 1;
            }
        };
        self.m_cards = shuffled_cards;
    }

    fn pop_card(ref self: ComponentDealer) -> Option<EnumCard> {
        if self.m_cards.is_empty() {
            return Option::None;
        }

        return self.m_cards.pop_front();
    }
}

#[generate_trait]
impl DeckImpl of IDeck {
    fn add(ref self: ComponentDeck, mut bc: EnumCard) -> () {
        if let Option::Some(_) = self.contains(@bc.get_name()) {
            panic!("{0}", EnumMoveError::CardAlreadyPresent);
        }

        self.m_cards.append(bc);
    }

    fn contains(self: @ComponentDeck, bc_name: @ByteArray) -> Option<usize> {
        let mut index = 0;
        let mut found = Option::None;

        while index < self.m_cards.len() {
            if let Option::Some(bc_found) = self.m_cards.get(index) {
                let bc_found = bc_found.unbox();
                if bc_name == @bc_found.get_name() {
                    found = Option::Some(index);
                    break;
                }
            }
        };
        return found;
    }

    fn contains_type(self: @ComponentDeck, bc_type : @EnumBlockchainType) -> Option<usize> {
        let mut index = 0;
        let mut found = Option::None;

        while let Option::Some(card) = self.m_cards.get(index) {
            match card.unbox() {
                EnumCard::Blockchain(bc_struct) => {
                    if bc_type == bc_struct.m_bc_type {
                        found = Option::Some(index);
                        break;
                    }
                },
                _ => {}
            };
            index += 1;
        };
        return found;
    }

    fn remove(ref self: ComponentDeck, card_name: @ByteArray) -> () {
        if let Option::Some(index_found) = self.contains(card_name) {
            let mut new_array = ArrayTrait::new();

            let mut index = 0;
            while let Option::Some(card) = self.m_cards.pop_front() {
                if index == index_found {
                    continue;
                }

                new_array.append(card);
                index += 1;
            };
        }
    }

    fn get_asset_group_for(self: @ComponentDeck, bc: @StructBlockchain) -> Option<Array<StructBlockchain>> {
        let mut index: usize = 0;
        let mut asset_group_array: Array<StructBlockchain> = ArrayTrait::new();
        let mut asset_group: Option<Array<StructBlockchain>> = Option::None;
        let mut total_fee: u8 = 0;

        while let Option::Some(card) = self.m_cards.get(index) {
            match card.unbox() {
                EnumCard::Blockchain(bc_struct) => {
                    if bc_struct.m_bc_type == bc.m_bc_type{
                        total_fee += *bc.m_fee;
                        asset_group_array.append(bc.clone());
                    }
                },
                _ => {}
            };

            index += 1;
        };

        if self.check_complete_set(asset_group_array.span(), bc.m_bc_type) {
            asset_group = Option::Some(asset_group_array);
        }
        return asset_group;
    }

    fn check_complete_set(self: @ComponentDeck, asset_group_array: Span<StructBlockchain>,
            bc_type: @EnumBlockchainType) -> bool {
        return match bc_type {
            EnumBlockchainType::Immutable(_) => { return false; },
            EnumBlockchainType::Blue(_) | EnumBlockchainType::DarkBlue(_) | EnumBlockchainType::Gold(_) => {
                if asset_group_array.len() == 2 {
                    return true;
                }
                return false;
            },
            EnumBlockchainType::LightBlue(_) => {
                if asset_group_array.len() == 4 {
                    return true;
                }
                return false;
            },
            _ => {
                if asset_group_array.len() == 3 {
                    return true;
                }
                return false;
            }
        };
    }
}

#[generate_trait]
impl EnumBlockchainTypeImpl of IEnumBlockchainType {
    fn get_boost_array(self: @EnumBlockchainType) -> Array<u8> {
        return match self {
            EnumBlockchainType::Immutable => {
                return array![];
            },
            EnumBlockchainType::Blue => {
                return array![1, 2];
            },
            EnumBlockchainType::DarkBlue => {
                return array![3, 8];
            },
            EnumBlockchainType::Gold => {
                return array![1, 2];
            },
            EnumBlockchainType::Green => {
                return array![1, 3, 5];
            },
            EnumBlockchainType::Grey => {
                return array![1, 2, 4];
            },
            EnumBlockchainType::LightBlue => {
                return array![1, 2, 3, 4];
            },
            EnumBlockchainType::Pink => {
                return array![1, 2, 3];
            },
            EnumBlockchainType::Purple => {
                return array![2, 4, 6];
            },
            EnumBlockchainType::Red => {
                return array![2, 4, 7];
            },
            EnumBlockchainType::Yellow => {
                return array![2, 3, 6];
            },
        };
    }
}

#[generate_trait]
impl EnumCardImpl of IEnumCard {
    fn distribute(ref self: EnumCard, in_container: Array<EnumCard>) -> Array<EnumCard> {
        assert!(self.get_index() > 0, "No more indices left for {0}", self);

        let mut new_array = ArrayTrait::new();
        while self.get_index() != 0 {
            new_array.append(self.remove_one_index());
        };
        return new_array;
    }

    fn get_index(self: @EnumCard) -> u8 {
        return match self {
            EnumCard::Asset(data) => {
                return *data.m_index;
            },
            EnumCard::Blockchain(_data) => {
                return 1;
            },
            EnumCard::ChainReorg(data) => {
                return *data.m_index;
            },
            EnumCard::ClaimYield(data) => {
                return *data.m_index;
            },
            EnumCard::GasFee(data) => {
                return *data.m_index;
            },
            EnumCard::HardFork(data) => {
                return *data.m_index;
            },
            EnumCard::MEVBoost(data) => {
                return *data.m_index;
            },
            EnumCard::PriorityFee(data) => {
                return *data.m_index;
            },
            EnumCard::ReplayAttack(data) => {
                return *data.m_index;
            },
            EnumCard::SoftFork(data) => {
                return *data.m_index;
            },
            EnumCard::FrontRun(data) => {
                return *data.m_index;
            },
            EnumCard::MajorityAttack(_) => {
                return 0;
            }
        };
    }

    fn get_name(self: @EnumCard) -> ByteArray {
        return self.into();
    }

    fn get_value(self: @EnumCard) -> u8 {
        return match self {
            EnumCard::Asset(data) => {
                return *data.m_value;
            },
            EnumCard::Blockchain(data) => {
                return *data.m_value;
            },
            EnumCard::ChainReorg(data) => {
                return *data.m_value;
            },
            EnumCard::ClaimYield(data) => {
                return *data.m_value;
            },
            EnumCard::GasFee(data) => {
                return *data.m_value;
            },
            EnumCard::HardFork(data) => {
                return *data.m_value;
            },
            EnumCard::MEVBoost(data) => {
                return *data.m_value;
            },
            EnumCard::PriorityFee(data) => {
                return *data.m_value;
            },
            EnumCard::ReplayAttack(data) => {
                return *data.m_value;
            },
            EnumCard::SoftFork(data) => {
                return *data.m_value;
            },
            EnumCard::FrontRun(data) => {
                return *data.m_value;
            },
            EnumCard::MajorityAttack(data) => {
                return *data.m_value;
            }
        };
    }

    fn remove_one_index(self: @EnumCard) -> EnumCard {
        return match self.clone() {
            EnumCard::Asset(mut data) => {
                assert!(data.m_index > 0, "No more indices left for {0}", data);
                data.m_index -= 1;
                return EnumCard::Asset(data);
            },
            EnumCard::ChainReorg(mut data) => {
                assert!(data.m_index > 0, "No more indices left for {0}", data);
                data.m_index -= 1;
                return EnumCard::ChainReorg(data);
            },
            EnumCard::ClaimYield(mut data) => {
                assert!(data.m_index > 0, "No more indices left for {0}", data);
                data.m_index -= 1;
                return EnumCard::ClaimYield(data);
            },
            EnumCard::GasFee(mut data) => {
                assert!(data.m_index > 0, "No more indices left for {0}", data);
                data.m_index -= 1;
                return EnumCard::GasFee(data);
            },
            EnumCard::HardFork(mut data) => {
                assert!(data.m_index > 0, "No more indices left for {0}", data);
                data.m_index -= 1;
                return EnumCard::HardFork(data);
            },
            EnumCard::MEVBoost(mut data) => {
                assert!(data.m_index > 0, "No more indices left for {0}", data);
                data.m_index -= 1;
                return EnumCard::MEVBoost(data);
            },
            EnumCard::PriorityFee(mut data) => {
                assert!(data.m_index > 0, "No more indices left for {0}", data);
                data.m_index -= 1;
                return EnumCard::PriorityFee(data);
            },
            EnumCard::ReplayAttack(mut data) => {
                assert!(data.m_index > 0, "No more indices left for {0}", data);
                data.m_index -= 1;
                return EnumCard::ReplayAttack(data);
            },
            EnumCard::SoftFork(mut data) => {
                assert!(data.m_index > 0, "No more indices left for {0}", data);
                data.m_index -= 1;
                return EnumCard::SoftFork(data);
            },
            EnumCard::FrontRun(mut data) => {
                assert!(data.m_index > 0, "No more indices left for {0}", data);
                data.m_index -= 1;
                return EnumCard::FrontRun(data);
            },
            EnumCard::MajorityAttack(mut data) => {
                assert!(data.m_index > 0, "No more indices left for {0}", data);
                data.m_index -= 1;
                return EnumCard::MajorityAttack(data);
            },
            _ => { return self.clone(); }
        };
    }

    fn is_asset(self: @EnumCard) -> bool {
        return match self {
            EnumCard::Asset(_) => true,
            _ => false
        };
    }

    fn is_blockchain(self: @EnumCard) -> bool {
        return match self {
            EnumCard::Blockchain(_) => true,
            _ => false
        };
    }
}

#[generate_trait]
impl GameImpl of IGame {
    fn add_player(ref self: ComponentGame, mut new_player: ContractAddress) -> () {
        assert!(self.contains_player(@new_player).is_none(), "Player already exists");
        self.m_players.append(new_player);
        return ();
    }

    fn contains_player(self: @ComponentGame, player: @ContractAddress) -> Option<usize> {
        let mut index = 0;
        let mut found = Option::None;

        while index < self.m_players.len() {
            if let Option::Some(player_found) = self.m_players.get(index) {
                if player == player_found.unbox() {
                    found = Option::Some(index);
                    break;
                }
            }
            index += 1;
        };
        return found;
    }

    fn remove_player(ref self: ComponentGame, player: @ContractAddress) -> () {
        if let Option::Some(index_found) = self.contains_player(player) {
            let mut new_array = ArrayTrait::new();

            let mut index = 0;
            while let Option::Some(player) = self.m_players.pop_front() {
                if index == index_found {
                    continue;
                }

                new_array.append(player);
                index += 1;
            };
        }
    }

    fn assign_next_turn(ref self: ComponentGame, is_start: bool) -> () {
        if is_start {
            assert!(!self.m_players.is_empty(), "No players in game");
            self.m_player_in_turn = *self.m_players.at(0);
            return;
        }

        if let Option::Some(position) = self.contains_player(@self.m_player_in_turn) {
            if position + 1 == self.m_players.len() {
                self.m_player_in_turn = *self.m_players.at(0);
                return;
            }
            assert!(self.m_players.get(position + 1).is_some(), "Player not found");
            self.m_player_in_turn = *self.m_players.at(position + 1);
        }
    }
}

#[generate_trait]
impl GasFeeImpl of IGasFee {
    fn new(players_affected: EnumPlayerTarget, bc_affected: EnumGasFeeType,
        set_applied: Array<StructBlockchain>, value: u8, copies_left: u8) -> ActionGasFee nopanic {
        return ActionGasFee {
            m_players_affected: players_affected,
            m_set_applied: set_applied,
            m_blockchain_type_affected: bc_affected,
            m_color_chosen: Option::None,
            m_value: value,
            m_index: copies_left
        };
    }

    fn get_fee(self: @ActionGasFee) -> u8 {
        return *self.m_set_applied.at(0).m_bc_type.get_boost_array().at(self.m_set_applied.len());
    }
}

#[generate_trait]
impl HandImpl of IHand {
    fn new(owner: ContractAddress, cards: Array<EnumCard>) -> ComponentHand {
        return ComponentHand {
            m_ent_owner: owner,
            m_cards: cards
        };
    }

    fn add(ref self: ComponentHand, mut card: EnumCard) -> () {
        if self.m_cards.len() == 9 {
            return panic!("Too many cards held");
        }

        self.m_cards.append(card);
    }

    fn contains(self: @ComponentHand, card_name: @ByteArray) -> Option<usize> {
        let mut index: usize = 0;

        return loop {
            if index >= self.m_cards.len() {
                break Option::None;
            }

            if @self.m_cards.at(index).get_name() == card_name {
                break Option::Some(index);
            }
            index += 1;
        };
    }

    fn remove(ref self: ComponentHand, card_name: @ByteArray) -> () {
        if let Option::Some(index_found) = self.contains(card_name) {
            let mut index: usize = 0;
            let mut new_array: Array<EnumCard> = ArrayTrait::new();
            while let Option::Some(card) = self.m_cards.pop_front() {
                if index == index_found {
                    continue;
                }
                new_array.append(card);
                index += 1;
            };
            self.m_cards = new_array;
        }
    }
}

#[generate_trait]
impl DepositImpl of IDeposit {
    fn new(owner: ContractAddress, cards: Array<EnumCard>, value: u8) -> ComponentDeposit {
        return ComponentDeposit {
            m_ent_owner: owner,
            m_cards: cards,
            m_total_value: value
        };
    }

    fn add(ref self: ComponentDeposit, mut card: EnumCard) -> () {
        assert!(!card.is_blockchain(), "Blockchains cannot be added to money pile");

        self.m_total_value += card.get_value();
        self.m_cards.append(card);
        return ();
    }

    fn contains(self: @ComponentDeposit, card_name: @ByteArray) -> Option<usize> {
        let mut index: usize = 0;

        return loop {
            if index >= self.m_cards.len() {
                break Option::None;
            }

            if @self.m_cards.at(index).get_name() == card_name {
                break Option::Some(index);
            }

            index += 1;
        };
    }

    fn remove(ref self: ComponentDeposit, card_name: @ByteArray) -> () {
        if let Option::Some(index_found) = self.contains(card_name) {
            self.m_total_value -= self.m_cards.at(index_found).get_value();
            let mut new_array: Array<EnumCard> = ArrayTrait::new();
            let mut index: usize = 0;
            while let Option::Some(card) = self.m_cards.pop_front() {
                if index == index_found {
                    continue;
                }

                new_array.append(card);
                index += 1;
            };
            self.m_cards = new_array;
        }
        return ();
    }
}

#[generate_trait]
impl PlayerImpl of IPlayer {
    fn new(owner: ContractAddress, username: ByteArray) -> ComponentPlayer {
        return ComponentPlayer {
            m_ent_owner: owner,
            m_username: username,
            m_moves_remaining: 3,
            m_score: 0,
            m_sets: 0,
            m_has_drawn: false,
            m_in_debt: Option::None
        };
    }

    fn get_debt(self: @ComponentPlayer) -> Option<u8> {
        return self.m_in_debt.clone();
    }
}

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
/////////////////////////////// ENUMS /////////////////////////////////
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////

#[derive(Drop, Serde, Copy, PartialEq, Introspect, Debug)]
enum EnumBlockchainType {
    Immutable,
    Blue,
    DarkBlue,
    Gold,
    Green,
    Grey,
    LightBlue,
    Pink,
    Purple,
    Red,
    Yellow,
}

#[derive(Drop, Serde, Clone, PartialEq, Introspect, Debug)]
enum EnumCard {
    Asset: StructAsset,
    Blockchain: StructBlockchain,
    ChainReorg: ActionChainReorg,
    ClaimYield: ActionClaimYield,
    GasFee: ActionGasFee,
    HardFork: ActionHardFork,
    MEVBoost: ActionMEVBoost,
    PriorityFee: ActionPriorityFee,
    SoftFork: ActionSoftFork,
    ReplayAttack: ActionReplayAttack,
    FrontRun: ActionFrontrun,
    MajorityAttack: ActionMajorityAttack
}

#[derive(Drop, Copy, Serde, PartialEq, Introspect, Debug)]
enum EnumPlayerTarget {
    All: (),
    None: (),
    One: ContractAddress,
}

#[derive(Drop, Copy, Serde, PartialEq, Introspect, Debug)]
enum EnumGasFeeType {
    Any: EnumBlockchainType,
    AgainstTwo: (EnumBlockchainType, EnumBlockchainType),
}

#[derive(Drop, Copy, Serde, PartialEq, Introspect, Debug)]
enum EnumGameState {
    WaitingForPlayers: (),
    Started: ()
}

#[derive(Drop, Copy, Serde, PartialEq, Introspect, Debug)]
enum EnumMoveError {
    CardAlreadyPresent,
    CardNotFound,
    NotEnoughMoves,
    SetAlreadyPresent
}
