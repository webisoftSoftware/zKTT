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
use origami_random::deck::{Deck, DeckTrait};
use core::fmt::{Display, Formatter, Error};

////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////// COMPONENTS /////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

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
    m_players: Array<ContractAddress>
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
    m_state: EnumPlayerState,
    m_in_debt: Option<u8>
}

/// Component that represents a turn in the game.
///
/// Per player.
#[derive(Drop, Serde, Clone, Debug)]
#[dojo::model]
struct ComponentTurn {
    #[key]
    m_ent_owner: ContractAddress,
    m_username: ByteArray,
    m_moves_remaining: u8,
    m_score: u32,
    m_sets: u8,
    m_state: EnumPlayerState,
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
    m_copies_left: u8
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
    m_value: u8,
    m_copies_left: u8
}

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////// ACTIONS /////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

/// Card that allows a player to draw two additional cards, and make it only count as one move.
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct ActionPriorityFee {
    m_value: u8,
    m_copies_left: u8
}

/// Card that allows a player to steal a blockchain from another player's deck.
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct ActionFrontrun {
    m_owner: ContractAddress,
    m_blockchain: StructBlockchain,
    m_value: u8,
    m_copies_left: u8
}

/// One player pays a gas fee for each blockchain you own in a selected color.
/// OR
/// Every player pays a gas fee for each blockchain you own in either color.
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct ActionGasFee {
    m_players_affected: Array<ContractAddress>,
    // If there is no Blockchain specified, it can be applied to any Blockchain.
    m_blockchain_type_affected: EnumBlockchainType,
    m_boost: Array<u8>,
    m_count: Option<u8>,  // How many Blockchains stacked.
    m_value: u8,
    m_copies_left: u8
}

/// Useable within 10 seconds of certain Onchain Events - cancels other players Onchain Event card.
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct ActionHardFork {
    m_value: u8,
    m_copies_left: u8
}

/// Steal an asset group from an opponent.
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct ActionMajorityAttack {
    m_owner: ContractAddress,
    m_name: ByteArray,
    m_set: Array<StructBlockchain>,
    m_value: u8,
    m_copies_left: u8
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

impl StructAssetDisplay of Display<StructAsset> {
    fn fmt(self: @StructAsset, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Asset: {0}, Value: {1}, Copies Left: {2}",
         self.m_name, *self.m_value, *self.m_copies_left);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl StructBlockchainDisplay of Display<StructBlockchain> {
    fn fmt(self: @StructBlockchain, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Blockchain: {0}, Type: {1}, Fee: {2}, Value {3}, Copies Left: {4}",
         self.m_name, self.m_bc_type, *self.m_fee, *self.m_value, *self.m_copies_left);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl ActionFrontrunDisplay of Display<ActionFrontrun> {
    fn fmt(self: @ActionFrontrun, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Steal Blockchain: Original_owner: {0}, Blockchain: {1},
        Value {2}, Copies Left: {3}", starknet::contract_address_to_felt252(*self.m_owner),
         self.m_blockchain, *self.m_value, *self.m_copies_left);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl ActionHardForkDisplay of Display<ActionHardFork> {
    fn fmt(self: @ActionHardFork, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Deny Card: Value {0}, Copies Left {1}", *self.m_value,
        *self.m_copies_left);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl ActionPriorityFeeDisplay of Display<ActionPriorityFee> {
    fn fmt(self: @ActionPriorityFee, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Draw Two Cards: Value {0}, Copies Left {1}",
         *self.m_value, *self.m_copies_left);
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
            EnumCard::StealBlockchain(data) => {
                let str: ByteArray = format!("{data}");
                f.buffer.append(@str);
            },
            EnumCard::StealAssetGroup(data) => {
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
        let str: ByteArray = format!("Targeted Blockchain: {0} Value {1}, Copies Left {2}",
         self.m_blockchain_type_affected, *self.m_value, *self.m_copies_left);
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

impl PlayerDisplay of Display<ComponentPlayer> {
    fn fmt(self: @ComponentPlayer, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Player: {0}, Asset Groups Owned: {1}, Moves remaining: {2}, Score: {3}",
         self.m_username, *self.m_sets, *self.m_moves_remaining, *self.m_score);
        f.buffer.append(@str);
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
        return lhs.m_name == rhs.m_name && lhs.m_copies_left == rhs.m_copies_left;
    }
}

impl StructBlockchainEq of PartialEq<StructBlockchain> {
    fn eq(lhs: @StructBlockchain, rhs: @StructBlockchain) -> bool {
        return lhs.m_name == rhs.m_name && lhs.m_copies_left == rhs.m_copies_left;
    }
}

impl ActionFrontrunEq of PartialEq<ActionFrontrun> {
    fn eq(lhs: @ActionFrontrun, rhs: @ActionFrontrun) -> bool {
        return lhs.m_copies_left == rhs.m_copies_left;
    }
}

impl ActionHardForkEq of PartialEq<ActionHardFork> {
    fn eq(lhs: @ActionHardFork, rhs: @ActionHardFork) -> bool {
        return lhs.m_copies_left == rhs.m_copies_left;
    }
}

impl ActionPriorityFeeEq of PartialEq<ActionPriorityFee> {
    fn eq(lhs: @ActionPriorityFee, rhs: @ActionPriorityFee) -> bool {
        return lhs.m_copies_left == rhs.m_copies_left;
    }
}

impl ActionGasFeeEq of PartialEq<ActionGasFee> {
    fn eq(lhs: @ActionGasFee, rhs: @ActionGasFee) -> bool {
        return lhs.m_copies_left == rhs.m_copies_left;
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

impl EnumCardInto of Into<EnumCard, ByteArray> {
    fn into(self: EnumCard) -> ByteArray {
        return match self {
            EnumCard::Asset(asset_struct) => format!("{0}", asset_struct.m_name),
            EnumCard::Blockchain(bc_struct) => format!("{0}", bc_struct.m_name),
            EnumCard::GasFee(_) => "Gas Fee",
            EnumCard::HardFork(_) => "Hardfork",
            EnumCard::PriorityFee(_) => "Priority Fee",
            EnumCard::StealBlockchain(_) => "Frontrun",
            EnumCard::StealAssetGroup(_) => "51% Attack",
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
            m_copies_left: copies_left
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
    fn new(name: ByteArray, bc_type: EnumBlockchainType, fee: u8, value: u8, copies_left: u8) -> StructBlockchain nopanic {
        return StructBlockchain {
            m_name: name,
            m_bc_type: bc_type,
            m_fee: fee,
            m_value: value,
            m_copies_left: copies_left
        };
    }
}

#[generate_trait]
impl StructPriorityFeeImpl of IDraw {
    fn new(value: u8, copies_left: u8) -> ActionPriorityFee nopanic {
        return ActionPriorityFee {
            m_value: value,
            m_copies_left: copies_left
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
        let mut deck = DeckTrait::new(seed, self.m_cards.len());

        while deck.remaining > 0 {
            // Draw a random number from 0 to 105.
            let card_index: u8 = deck.draw();

            if let Option::Some(_) = self.m_cards.get(card_index.into()) {
                shuffled_cards.append(self.m_cards[card_index.into()].clone());
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
        if let Option::Some(_) = self.contains(@bc) {
            panic!("{0}", EnumMoveError::CardAlreadyPresent);
        }

        self.m_cards.append(bc);
    }

    fn contains(self: @ComponentDeck, bc: @EnumCard) -> Option<usize> {
        let mut index = 0;
        let mut found = Option::None;

        while index < self.m_cards.len() {
            if let Option::Some(bc_found) = self.m_cards.get(index) {
                if bc == bc_found.unbox() {
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

    fn remove(ref self: ComponentDeck, card_name: @EnumCard) -> () {
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
            EnumBlockchainType::Blue(_) => {
                if asset_group_array.len() == 2 {
                    return true;
                }
                return false;
            },
            EnumBlockchainType::DarkBlue(_) => {
                if asset_group_array.len() == 2 {
                    return true;
                }
                return false;
            },
            EnumBlockchainType::Gold(_) => {
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
impl EnumCardImpl of IEnumCard {
    fn distribute(ref self: EnumCard, in_container: Array<EnumCard>) -> Array<EnumCard> {
        assert!(self.get_copies_left() > 0, "No more copies left for {0}", self);

        let mut new_array = ArrayTrait::new();
        while self.get_copies_left() != 0 {
            new_array.append(self.remove_one_copy());
        };
        return new_array;
    }

    fn get_copies_left(self: @EnumCard) -> u8 {
        return match self {
            EnumCard::Asset(data) => {
                return *data.m_copies_left;
            },
            EnumCard::Blockchain(data) => {
                return *data.m_copies_left;
            },
            EnumCard::GasFee(data) => {
                return *data.m_copies_left;
            },
            EnumCard::HardFork(data) => {
                return *data.m_copies_left;
            },
            EnumCard::PriorityFee(data) => {
                return *data.m_copies_left;
            },
            EnumCard::StealBlockchain(data) => {
                return *data.m_copies_left;
            },
            EnumCard::StealAssetGroup(_) => {
                return 0;
            }
        };
    }

    fn get_name(self: @EnumCard) -> ByteArray {
        return match self {
            EnumCard::Asset(data) => {
                return data.m_name.clone();
            },
            EnumCard::Blockchain(data) => {
                return data.m_name.clone();
            },
            EnumCard::GasFee(_) => {
                return "Gas Fee";
            },
            EnumCard::HardFork(_) => {
                return "Hardfork";
            },
            EnumCard::PriorityFee(_) => {
                return "Priority Fee";
            },
            EnumCard::StealBlockchain(_) => {
                return "Frontrun";
            },
            EnumCard::StealAssetGroup(_) => {
                return "51% Attack";
            }
        };
    }

    fn get_value(self: @EnumCard) -> u8 {
        return match self {
            EnumCard::Asset(data) => {
                return *data.m_value;
            },
            EnumCard::Blockchain(data) => {
                return *data.m_value;
            },
            EnumCard::GasFee(data) => {
                return *data.m_value;
            },
            EnumCard::HardFork(data) => {
                return *data.m_value;
            },
            EnumCard::PriorityFee(data) => {
                return *data.m_value;
            },
            EnumCard::StealBlockchain(data) => {
                return *data.m_value;
            },
            EnumCard::StealAssetGroup(data) => {
                return *data.m_value;
            }
        };
    }

    fn remove_one_copy(self: @EnumCard) -> EnumCard {
        return match self.clone() {
            EnumCard::Asset(mut data) => {
                assert!(data.m_copies_left > 0, "No more copies left for {0}", data);
                data.m_copies_left -= 1;
                return EnumCard::Asset(data.clone());
            },
            EnumCard::Blockchain(mut data) => {
                assert!(data.m_copies_left > 0, "No more copies left for {0}", data);
                data.m_copies_left -= 1;
                return EnumCard::Blockchain(data.clone());
            },
            EnumCard::GasFee(mut data) => {
                assert!(data.m_copies_left > 0, "No more copies left for {0}", data);
                data.m_copies_left -= 1;
                return EnumCard::GasFee(data.clone());
            },
            EnumCard::HardFork(mut data) => {
                assert!(data.m_copies_left > 0, "No more copies left for {0}", data);
                data.m_copies_left -= 1;
                return EnumCard::HardFork(data.clone());
            },
            EnumCard::PriorityFee(mut data) => {
                assert!(data.m_copies_left > 0, "No more copies left for {0}", data);
                data.m_copies_left -= 1;
                return EnumCard::PriorityFee(data.clone());
            },
            EnumCard::StealBlockchain(mut data) => {
                assert!(data.m_copies_left > 0, "No more copies left for {0}", data);
                data.m_copies_left -= 1;
                return EnumCard::StealBlockchain(data.clone());
            },
            EnumCard::StealAssetGroup(mut data) => {
                assert!(data.m_copies_left > 0, "No more copies left for {0}", data);
                data.m_copies_left -= 1;
                return EnumCard::StealAssetGroup(data.clone());
            }
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
}

#[generate_trait]
impl GasFeeImpl of IGasFee {
    fn new(players: Array<ContractAddress>, bc_affected: EnumBlockchainType, boost: Array<u8>,
     count: Option<u8>, value: u8, copies_left: u8) -> ActionGasFee {
        return ActionGasFee {
            m_players_affected: players,
            // If there is no Blockchain specified, it can be applied to any Blockchain.
            m_blockchain_type_affected: bc_affected,
            m_boost: boost,
            m_count: count,  // How many Blockchains stacked.
            m_value: value,
            m_copies_left: copies_left
        };
    }

    fn get_fee(self: @ActionGasFee) -> Option<u8> {
        if self.m_count.is_none() {
            return Option::None;
        }

        return Option::Some(*self.m_boost.at(self.m_count.clone().unwrap().into()));
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

    fn contains(self: @ComponentHand, card: @EnumCard) -> Option<usize> {
        let mut index: usize = 0;

        return loop {
            if index >= self.m_cards.len() {
                break Option::None;
            }

            if self.m_cards.at(index) == card {
                break Option::Some(index);
            }
            index += 1;
        };
    }

    fn remove(ref self: ComponentHand, card: @EnumCard) -> () {
        if let Option::Some(index_found) = self.contains(card) {
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

    fn contains(self: @ComponentDeposit, card: @EnumCard) -> Option<usize> {
        let mut index: usize = 0;

        return loop {
            if index >= self.m_cards.len() {
                break Option::None;
            }

            if self.m_cards.at(index) == card {
                break Option::Some(index);
            }

            index += 1;
        };
    }

    fn remove(ref self: ComponentDeposit, card: @EnumCard) -> () {
        if let Option::Some(index_found) = self.contains(card) {
            self.m_total_value -= card.get_value();
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
            m_state: EnumPlayerState::TurnEnded,
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

#[derive(Drop, Serde, Clone, PartialEq, Introspect, Debug)]
enum EnumBlockchainType {
    Immutable: (),
    Blue: (),
    DarkBlue: (),
    Gold: (),
    Green: (),
    Grey: (),
    LightBlue: (),
    Pink: (),
    Purple: (),
    Red: (),
    Yellow: ()
}

#[derive(Drop, Serde, Clone, PartialEq, Introspect, Debug)]
enum EnumCard {
    Asset: StructAsset,
    Blockchain: StructBlockchain,
    GasFee: ActionGasFee,
    HardFork: ActionHardFork,
    PriorityFee: ActionPriorityFee,
    StealBlockchain: ActionFrontrun,
    StealAssetGroup: ActionMajorityAttack,
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect, Debug)]
enum EnumGameState {
    WaitingForPlayers: (),
    Started: ()
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect, Debug)]
enum EnumLocation {
    Deposit: (),
    Deck: ()
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect, Debug)]
enum EnumMoveError {
    CardAlreadyPresent: (),
    CardNotFound: (),
    NotEnoughMoves: (),
    SetAlreadyPresent: ()
}

#[derive(Copy, Drop, Serde, PartialEq, Introspect, Debug)]
enum EnumPlayerState {
    NotJoined: (),
    Joined: (),
    DrawnCards: (),
    TurnStarted: (),
    TurnEnded: (),
}