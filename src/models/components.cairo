////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////   _______  _       __________________  /////////////////////////////
///////////////////////////////  / ___   )| \    /\\__   __/\__   __/  /////////////////////////////
///////////////////////////////  \/   )  ||  \  / /   ) (      ) (     /////////////////////////////
///////////////////////////////      /   )|  (_/ /    | |      | |     /////////////////////////////
///////////////////////////////     /   / |   _ (     | |      | |     /////////////////////////////
///////////////////////////////    /   /  |  ( \ \    | |      | |     /////////////////////////////
///////////////////////////////   /   (_/\|  /  \ \   | |      | |     /////////////////////////////
///////////////////////////////  (_______/|_/    \/   )_(      )_(     /////////////////////////////
///////////////////////////////                                        /////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
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

use starknet::ContractAddress;
use core::fmt::{Display, Formatter, Error};

////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////// COMPONENTS /////////////////////////////////
////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////

/// Component that represents the card itself, useful for determining the rightful owner.
///
/// Per card in deck.
#[derive(Drop, Serde, Clone, Debug)]
#[dojo::model]
struct ComponentCard {
    #[key]
    m_ent_owner: ContractAddress,
    m_type: EnumCard,
    m_is_owner: bool
}

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

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////// STRUCTS /////////////////////////////////
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

/// Card containing the info about an asset (card that only has monetary value).
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct StructAsset {
    m_owner: ContractAddress,
    m_name: ByteArray,
    m_value: u8,
    m_copies_left: u8
}

/// Card containing the info about a specific asset group (set of matching blockchains).
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct StructAssetGroup {
    m_owner: ContractAddress,
    m_set: Array<StructBlockchain>,
    m_total_fee_value: u8
}

/// Card containing the info about a specific blockchain.
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct StructBlockchain {
    m_owner: ContractAddress,
    m_name: ByteArray,
    m_bc_type: EnumBlockchainType,
    m_fee: u8,
    m_value: u8,
    m_copies_left: u8
}

/// Card that allows a player to draw two cards, and make it only count as one move.
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct StructDraw {
    m_owner: ContractAddress,
    m_value: u8,
    m_copies_left: u8
}

/// Make one or more players pay you a fee depending on the blockchain rent (determined by how
/// many blockchains are stacked on top of each other (same color).
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct StructGasFee {
    m_owner: ContractAddress,
    m_name: ByteArray,
    m_players_affected: Array<ContractAddress>,
    // If there is no Blockchain specified, it can be applied to any Blockchain.
    m_blockchain_type_affected: EnumBlockchainType,
    m_boost: Array<u8>,
    m_count: Option<u8>,  // How many Blockchains stacked.
    m_value: u8,
    m_copies_left: u8
}

/// Specify where to move a card.
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct StructLocation {
    m_location_addr: ContractAddress,
    m_location: EnumLocation
}

/// Steal an asset group from an opponent.
#[derive(Drop, Serde, Clone, Introspect, Debug)]
struct StructMajorityAttack {
    m_owner: ContractAddress,
    m_name: ByteArray,
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

impl StructAssetGroupDisplay of Display<StructAssetGroup> {
    fn fmt(self: @StructAssetGroup, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Total Fee: {0}", *self.m_total_fee_value);
        f.buffer.append(@str);

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

impl StructBlockchainDisplay of Display<StructBlockchain> {
    fn fmt(self: @StructBlockchain, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Blockchain: {0}, Type: {1}, Fee: {2}, Value {3}, Copies Left: {4}",
         self.m_name, self.m_bc_type, *self.m_fee, *self.m_value, *self.m_copies_left);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl StructDrawDisplay of Display<StructDraw> {
    fn fmt(self: @StructDraw, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Draw Two Cards: Value {0}, Copies Left: {1}", *self.m_value,
         *self.m_copies_left);
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
            EnumCard::Claim(data) => {
                let str: ByteArray = format!("{data}");
                f.buffer.append(@str);
            },
            EnumCard::Deny(data) => {
                let str: ByteArray = format!("{data}");
                f.buffer.append(@str);
            },
            EnumCard::Draw(data) => {
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

impl StructGasFeeDisplay of Display<StructGasFee> {
    fn fmt(self: @StructGasFee, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Gas Fee: {0}, Targeted Blockchain: {1}, Value: {2}\n
            Copies Left: {3}", self.m_name, self.m_blockchain_type_affected, *self.m_value,
             *self.m_copies_left);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl StructMajorityAttackDisplay of Display<StructMajorityAttack> {
    fn fmt(self: @StructMajorityAttack, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("51% Attack: {0}, Value: {1}, Copies Left: {2}", self.m_name,
            *self.m_value, *self.m_copies_left);
        f.buffer.append(@str);
        return Result::Ok(());
    }
}

impl PlayerDisplay of Display<ComponentPlayer> {
    fn fmt(self: @ComponentPlayer, ref f: Formatter) -> Result<(), Error> {
        let str: ByteArray = format!("Player: {0}, Asset Groups Owned: {1}, Moves remaining: {2},
         Score: {3}", self.m_username, *self.m_sets, *self.m_moves_remaining, *self.m_score);
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
        return lhs.m_name == rhs.m_name;
    }
}

impl StructAssetGroupEq of PartialEq<StructAssetGroup> {
    fn eq(lhs: @StructAssetGroup, rhs: @StructAssetGroup) -> bool {
        if lhs.m_total_fee_value != rhs.m_total_fee_value || lhs.m_set.len() != rhs.m_set.len() {
            return false;
        }

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

impl StructDrawEq of PartialEq<StructDraw> {
    fn eq(lhs: @StructDraw, rhs: @StructDraw) -> bool {
        return true;
    }
}

impl StructGasFeeEq of PartialEq<StructGasFee> {
    fn eq(lhs: @StructGasFee, rhs: @StructGasFee) -> bool {
        return lhs.m_name == rhs.m_name;
    }
}

impl StructMajorityAttackEq of PartialEq<StructMajorityAttack> {
    fn eq(lhs: @StructMajorityAttack, rhs: @StructMajorityAttack) -> bool {
        return true;
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
            EnumCard::Claim(gas_fee_struct) => format!("{0}", gas_fee_struct.m_name),
            EnumCard::Deny(_) => "Hardfork",
            EnumCard::Draw(_) => "Priority Fee",
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
    fn new(owner: ContractAddress, name: ByteArray, value: u8, copies_left: u8) -> StructAsset {
        return StructAsset {
            m_owner: owner,
            m_name: name,
            m_value: value,
            m_copies_left: copies_left
        };
    }
}

#[generate_trait]
impl StructAssetGroupImpl of IAssetGroup {
    fn new(owner: ContractAddress, blockchains: Array<StructBlockchain>, total_fee_value: u8) -> StructAssetGroup {
        return StructAssetGroup {
            m_owner: owner,
            m_set: blockchains,
            m_total_fee_value: total_fee_value
        };
    }
}

#[generate_trait]
impl StructBlockchainImpl of IBlockchain {
    fn new(owner: ContractAddress, name: ByteArray, bc_type: EnumBlockchainType, fee: u8, value: u8,
        copies_left: u8) -> StructBlockchain {
        return StructBlockchain {
            m_owner: owner,
            m_name: name,
            m_bc_type: bc_type,
            m_fee: fee,
            m_value: value,
            m_copies_left: copies_left
        };
    }
}

#[generate_trait]
impl CardImpl of ICard {
    fn new(owner: ContractAddress, card: EnumCard) -> ComponentCard {
        return ComponentCard {
            m_ent_owner: owner,
            m_type: card,
            m_is_owner: true
        };
    }
}

#[generate_trait]
impl StructDrawImpl of IDraw {
    fn new(owner: ContractAddress, value: u8, copies_left: u8) -> StructDraw {
        return StructDraw {
            m_owner: owner,
            m_value: value,
            m_copies_left: copies_left
        };
    }
}

#[generate_trait]
impl DealerImpl of IDealer {
    fn new(owner: ContractAddress, cards: Array<EnumCard>) -> ComponentDealer {
        return ComponentDealer {
            m_ent_owner: owner,
            m_cards: cards
        };
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
        let new_bc = bc.set_owner(self.m_ent_owner);
        self.m_cards.append(new_bc);
    }

    fn contains(ref self: ComponentDeck, bc: @EnumCard) -> Option<usize> {
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

    fn contains_type(ref self: ComponentDeck, bc_type : @EnumBlockchainType) -> Option<usize> {
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

    fn get_asset_group_for(self: @ComponentDeck, bc: @StructBlockchain) -> Option<StructAssetGroup> {
        let mut index: usize = 0;
        let mut asset_group_array: Array<StructBlockchain> = ArrayTrait::new();
        let mut asset_group: Option<StructAssetGroup> = Option::None;
        let mut total_fee: u8 = 0;

        while let Option::Some(card) = self.m_cards.get(index) {
            match card.unbox() {
                EnumCard::Blockchain(bc_struct) => {
                    if bc_struct.m_bc_type == bc.m_bc_type && bc.m_owner == self.m_ent_owner {
                        total_fee += *bc.m_fee;
                        asset_group_array.append(bc.clone());
                    }
                },
                _ => {}
            };

            index += 1;
        };

        if self.check_complete_set(@asset_group_array, bc.m_bc_type) {
            asset_group = Option::Some(IAssetGroup::new(*self.m_ent_owner, asset_group_array,
             total_fee));
        }
        return asset_group;
    }

    fn check_complete_set(self: @ComponentDeck, asset_group_array: @Array<StructBlockchain>,
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
    fn get_owner(self: @EnumCard) -> @ContractAddress {
        return match self {
            EnumCard::Asset(data) => {
                return data.m_owner;
            },
            EnumCard::Blockchain(data) => {
                return data.m_owner;
            },
            EnumCard::Claim(data) => {
                return data.m_owner;
            },
            EnumCard::Deny(data) => {
                return data.m_owner;
            },
            EnumCard::Draw(data) => {
                return data.m_owner;
            },
            EnumCard::StealBlockchain(data) => {
                return data.m_owner;
            },
            EnumCard::StealAssetGroup(data) => {
                return data.m_owner;
            }
        };
    }

    fn set_owner(self: EnumCard, new_owner: ContractAddress) -> EnumCard {
        return match self {
            EnumCard::Asset(data) => {
                let mut copy = data;
                copy.m_owner = new_owner;
                return EnumCard::Asset(copy);
            },
            EnumCard::Blockchain(data) => {
                let mut copy = data;
                copy.m_owner = new_owner;
                return EnumCard::Blockchain(copy);
            },
            EnumCard::Claim(data) => {
                let mut copy = data;
                copy.m_owner = new_owner;
                return EnumCard::Claim(copy);
            },
            EnumCard::Deny(data) => {
                let mut copy = data;
                copy.m_owner = new_owner;
                return EnumCard::Deny(copy);
            },
            EnumCard::Draw(data) => {
                return EnumCard::Draw(data);
            },
            EnumCard::StealBlockchain(StructBlockchain) => {
                let mut copy = StructBlockchain;
                copy.m_owner = new_owner;
                return EnumCard::StealBlockchain(copy);
            },
            EnumCard::StealAssetGroup(StructAsset_group) => {
                let mut copy = StructAsset_group;
                copy.m_owner = new_owner;
                return EnumCard::StealAssetGroup(copy);
            },
            _ => {
                return self;
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
            EnumCard::Claim(_) => {
                return "Gas Fee";
            },
            EnumCard::Deny(_) => {
                return "Hardfork";
            },
            EnumCard::Draw(_) => {
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
                return data.m_value.clone();
            },
            EnumCard::Blockchain(data) => {
                return data.m_value.clone();
            },
            EnumCard::Claim(data) => {
                return data.m_value.clone();
            },
            EnumCard::Deny(data) => {
                return data.m_value.clone();
            },
            EnumCard::Draw(data) => {
                return data.m_value.clone();
            },
            EnumCard::StealBlockchain(data) => {
                return data.m_value.clone();
            },
            EnumCard::StealAssetGroup(data) => {
                return data.m_total_fee_value.clone();
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
    fn new(owner: ContractAddress, name: ByteArray, players: Array<ContractAddress>,
        bc_affected: EnumBlockchainType, boost: Array<u8>, count: Option<u8>, value: u8,
        copies_left: u8) -> StructGasFee {
        return StructGasFee {
            m_owner: owner,
            m_name: name,
            m_players_affected: players,
            // If there is no Blockchain specified, it can be applied to any Blockchain.
            m_blockchain_type_affected: bc_affected,
            m_boost: boost,
            m_count: count,  // How many Blockchains stacked.
            m_value: value,
            m_copies_left: copies_left
        };
    }

    fn get_fee(self: @StructGasFee) -> Option<u8> {
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

    fn add(ref self: ComponentHand, card: EnumCard) -> () {
        if self.m_cards.len() == 9 {
            return panic!("Too many cards held");
        }

        // Transfer ownership.
        let new_card = card.set_owner(self.m_ent_owner);
        self.m_cards.append(new_card);
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

        let new_card = card.set_owner(self.m_ent_owner);
        self.m_total_value += new_card.get_value();
        self.m_cards.append(new_card);
        return ();
    }

    fn contains(ref self: ComponentDeposit, card: @EnumCard) -> Option<usize> {
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
    Claim: StructGasFee,  // Make other player(s) pay you a fee.
    Deny: StructMajorityAttack,  // Deny and avoid performing the action imposed.
    Draw: StructDraw, // Draw two additional cards.
    StealBlockchain: StructBlockchain,  // Steal a single Blockchain from a player's deck.
    StealAssetGroup: StructAssetGroup,  // Steal Asset Group from another player.
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