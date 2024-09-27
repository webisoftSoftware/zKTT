#[cfg(test)]
mod tests {
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use zktt::models::{GameComponent, CardComponent, DeckComponent, DealerComponent,
         HandComponent, MoneyPileComponent, PlayerComponent, EnumGameState, EnumMoveError,
          EnumCardCategory, EnumPlayerState, EnumBlockchainType,
           IBlockchain, IDeck, IDealer, IGameComponent, IPlayer, ICard, IHand, IAsset};

    fn create_cards(world_address: @ContractAddress) -> Array<CardComponent> {
        let mut container = ArrayTrait::new();

        // ASSET CARDS
        let asset = IAsset::new(*world_address, "ETH [1]", 1, 6);
        let ton = ICard::new(*world_address, EnumCardCategory::Asset(asset));
        container.append(ton);

        let blockchain = IBlockchain::new(*world_address, "Base", EnumBlockchainType::LightBlue, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        let blockchain = IBlockchain::new(*world_address, "Arbitrum", EnumBlockchainType::LightBlue, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        let asset = IAsset::new(*world_address, "ETH [10]", 10, 1);
        let ton = ICard::new(*world_address, EnumCardCategory::Asset(asset));
        container.append(ton);

        let blockchain = IBlockchain::new(*world_address, "Gnosis Chain", EnumBlockchainType::Green, 1, 1, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        let asset = IAsset::new(*world_address, "ETH [2]", 2, 5);
        let ton = ICard::new(*world_address, EnumCardCategory::Asset(asset));
        container.append(ton);

        let blockchain = IBlockchain::new(*world_address, "Blast", EnumBlockchainType::Yellow,  2, 3, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        let blockchain = IBlockchain::new(*world_address, "Celestia", EnumBlockchainType::Purple,  2, 3, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        let asset = IAsset::new(*world_address, "ETH [5]", 5, 2);
        let ton = ICard::new(*world_address, EnumCardCategory::Asset(asset));
        container.append(ton);

        let asset = IAsset::new(*world_address, "ETH [4]", 4, 3);
        let ton = ICard::new(*world_address, EnumCardCategory::Asset(asset));
        container.append(ton);

        // Fantom
        let blockchain = IBlockchain::new(*world_address, "Fantom", EnumBlockchainType::LightBlue, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        let asset = IAsset::new(*world_address, "ETH [3]", 3, 3);
        let ton = ICard::new(*world_address, EnumCardCategory::Asset(asset));
        container.append(ton);

        // Metis
        let blockchain = IBlockchain::new(*world_address, "Metis", EnumBlockchainType::LightBlue, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // GREEN
        // Canto
        let blockchain = IBlockchain::new(*world_address, "Canto", EnumBlockchainType::Green, 1, 1, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // Near
        let blockchain = IBlockchain::new(*world_address, "Near", EnumBlockchainType::Green, 1, 1, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // RED
        // Avalanche
        let blockchain = IBlockchain::new(*world_address, "Avalanche", EnumBlockchainType::Red, 2, 4, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // Kava
        let blockchain = IBlockchain::new(*world_address, "Kava", EnumBlockchainType::Red, 2, 4, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // Optimism
        let blockchain = IBlockchain::new(*world_address, "Optimism", EnumBlockchainType::Red, 2, 4, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // Silver
        // ZKSync
        let blockchain = IBlockchain::new(*world_address, "ZKSync", EnumBlockchainType::Silver, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // Linea
        let blockchain = IBlockchain::new(*world_address, "Linea", EnumBlockchainType::Silver, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // Aptos
        let blockchain = IBlockchain::new(*world_address, "Aptos", EnumBlockchainType::Silver, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // YELLOW
        // Scroll
        let blockchain = IBlockchain::new(*world_address, "Scroll", EnumBlockchainType::Yellow, 2, 3, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // Celo
        let blockchain = IBlockchain::new(*world_address, "Celo", EnumBlockchainType::Yellow,  2, 3, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // PURPLE
        // Polygon
        let blockchain = IBlockchain::new(*world_address, "Polygon", EnumBlockchainType::Purple, 2, 3, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // Solana
        let blockchain = IBlockchain::new(*world_address, "Solana", EnumBlockchainType::Purple,  2, 3, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // PINK
        // Polkadot
        let blockchain = IBlockchain::new(*world_address, "Polkadot", EnumBlockchainType::Pink, 1, 1, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // Osmosis
        let blockchain = IBlockchain::new(*world_address, "Osmosis", EnumBlockchainType::Pink, 1, 1, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // Taiko
        let blockchain = IBlockchain::new(*world_address, "Taiko", EnumBlockchainType::Pink, 1, 1, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // BLUE
        // Cosmos
        let blockchain = IBlockchain::new(*world_address, "Cosmos", EnumBlockchainType::Blue, 1, 1, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // Ton
        let blockchain = IBlockchain::new(*world_address, "Ton", EnumBlockchainType::Blue, 1, 1, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // DARK BLUE
        // Starknet
        let blockchain = IBlockchain::new(*world_address, "Starknet", EnumBlockchainType::DarkBlue, 3, 4, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // Ethereum
        let blockchain = IBlockchain::new(*world_address, "Ethereum", EnumBlockchainType::DarkBlue, 3, 4, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // GOLD
        // Bitcoin
        let blockchain = IBlockchain::new(*world_address, "Bitcoin", EnumBlockchainType::Gold, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        // Dogecoin
        let blockchain = IBlockchain::new(*world_address, "Dogecoin", EnumBlockchainType::Gold, 1, 2, 1);
        let bc = ICard::new(*world_address, EnumCardCategory::Blockchain(blockchain));
        container.append(bc);

        return container;
    }

    #[test]
    fn test_print() -> () {
        let caller = starknet::contract_address_const::<0x0>();
        let cards = create_cards(@caller);

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