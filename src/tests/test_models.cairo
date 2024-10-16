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


#[cfg(test)]
mod tests {
    use starknet::{ContractAddress, get_caller_address};
    use zktt::models::components::{ComponentGame, ComponentDeck, ComponentDealer,
         ComponentDeposit, ComponentHand, ComponentPlayer, EnumGameState, EnumMoveError,
          EnumCard, EnumBlockchainType, IEnumCard,
           IBlockchain, IDeck, IDealer, IGame, IPlayer, IHand, IAsset,
           StructAsset, StructBlockchain};
    use zktt::systems::game::table;


    #[test]
    fn test_cards_init() -> () {
        let mut array = array![
        EnumCard::Asset(IAsset::new("ETH [1]", 1, 6)),
        EnumCard::Asset(IAsset::new("ETH [2]", 1, 6)),
        EnumCard::Blockchain(IBlockchain::new("Optimism", EnumBlockchainType::Red, 2, 4)),
        EnumCard::Blockchain(IBlockchain::new("Osmosis", EnumBlockchainType::Pink, 1, 1)),
        EnumCard::Blockchain(IBlockchain::new("Polkadot", EnumBlockchainType::Pink, 1, 1)),
        EnumCard::Blockchain(IBlockchain::new("Polygon", EnumBlockchainType::Purple, 2, 3)),
        EnumCard::Blockchain(IBlockchain::new("Scroll", EnumBlockchainType::Yellow, 2, 3)),
        EnumCard::Blockchain(IBlockchain::new("Solana", EnumBlockchainType::Purple,  2, 3)),
        EnumCard::Blockchain(IBlockchain::new("Starknet", EnumBlockchainType::DarkBlue, 3, 4)),
        EnumCard::Blockchain(IBlockchain::new("Taiko", EnumBlockchainType::Pink, 1, 1)),
        EnumCard::Blockchain(IBlockchain::new("Ton", EnumBlockchainType::Blue, 1, 1)),
        EnumCard::Blockchain(IBlockchain::new("ZKSync", EnumBlockchainType::Grey, 1, 2))
         ];
        let new_array = table::_flatten(array);
        assert!(new_array.len() == 22, "There should have been 22 cards in deck!");
    }

    #[test]
    fn test_hands() -> () {
        let callers = array![starknet::contract_address_const::<0x0>(),
        starknet::contract_address_const::<0x1>(),
        starknet::contract_address_const::<0x2>()];

        let asset1: StructAsset = IAsset::new("ETH [1]", 1, 6);
        let asset2: StructAsset = IAsset::new("ETH [2]", 1, 6);
        let asset_card1 = EnumCard::Asset(asset1.clone());
        let asset_card2 = EnumCard::Asset(asset2.clone());

        let mut hand1 = IHand::new(*callers[0], array![asset_card1.clone()]);
        let hand2 = IHand::new(*callers[1], array![asset_card1.clone()]);
        let hand3 = IHand::new(*callers[2], array![asset_card2]);

        assert!(hand1 == hand2, "Hands should be identical even with different owners");
        assert!(hand2 != hand3, "Hands should NOT be equal");

        hand1.remove(@asset_card1.get_name());
        assert!(hand1.m_cards.is_empty(), "Hand should be empty");
    }
}