#[cfg(test)]
mod tests {
    use zktt::{models::{CardComponent, EnumCardCategory, BlockchainComponent, ICard}};

    #[test]
    fn test_print() -> () {
        let card1 = ICard::new(EnumCardCategory::Eth(2), 5);
        let card2 = ICard::new(EnumCardCategory::Blockchain(BlockchainComponent {
            ent_name: "Solana (SOL)",
            value: 1
        }), 1);

        println!("Card 1: {card1}\nCard 2: {card2}");
    }
}