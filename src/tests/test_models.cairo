////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////            ____________ //////////////////////////////////////
/////////////////////////////////////   ___| |/ /_   _|_   _| //////////////////////////////////////
/////////////////////////////////////  |_  / ' /  | |   | |   //////////////////////////////////////
/////////////////////////////////////   / /| . \  | |   | |   //////////////////////////////////////
/////////////////////////////////////  /___|_|\_\ |_|   |_|   //////////////////////////////////////
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

#[cfg(test)]
mod tests {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use zktt::models::components::{ComponentGame, ComponentDeck, ComponentDealer,
         ComponentHand, ComponentMoneyPile, ComponentPlayer, EnumGameState, EnumMoveError,
          EnumCard, EnumPlayerState, EnumBlockchainType,
           IBlockchain, IDeck, IDealer, IGame, IPlayer, IHand, IAsset};
    use zktt::systems::game::table;

    #[test]
    fn test_start() -> () {
        let callers = array![starknet::contract_address_const::<0x0>(),
         starknet::contract_address_const::<0x1>(),
         starknet::contract_address_const::<0x2>()];

        let cards = table::create_cards(callers.at(0));
        //table::distribute_cards()

        let mut index = 0;
        loop {
            if index >= cards.len() {
                break ();
            }

            println!("{0}", cards.at(index));
            index += 1;
        };
    }
}