use alloy::{
    eips::eip7702::Authorization,
    network::{TransactionBuilder, TransactionBuilder7702, TxSigner},
    node_bindings::Anvil,
    primitives::{Address, U256, address},
    providers::{Provider, ProviderBuilder},
    rpc::types::TransactionRequest,
    signers::{Signer, SignerSync, local::PrivateKeySigner},
    sol,
};
use eyre::{ErrReport, Result};
use std::env;
use std::str::FromStr;

sol!(
    #[sol(rpc)]
    "../src/EOAMultisend.sol"
);

async fn eoa_multisend(pk: PrivateKeySigner, calls: Vec<TransactionRequest>) -> Result<()> {
    let sepolia = "https://sepolia.etherscan.io".parse()?;
    let provider = ProviderBuilder::new()
        .wallet(pk.clone())
        .connect_http(sepolia);

    // let contract = EOAMultisend::deploy(&provider).await?;

    // let authorization = Authorization {
    //     chain_id: U256::from(11155111),
    //     // Reference to the contract that will be set as code for the authority.
    //     address: *contract.address(),
    //     nonce: provider.get_transaction_count(pk.address()).await?,
    // };
    Ok(())
}

#[tokio::main]
fn main() -> Result<()> {
    let anvil = Anvil::new().arg("--hardfork").arg("prague").try_spawn()?;
    let private_key: PrivateKeySigner = match env::var("PK") {
        Ok(pk) => PrivateKeySigner::from_str(pk.as_str())?,
        Err(_) => anvil.keys()[0].clone().into(),
    };

    let tx1 = TransactionRequest::default()
        .with_to(Address::ZERO)
        .with_value(U256::from(10000000000000));

    let tx2 = TransactionRequest::default()
        .with_to(address!("0x1111111111111111111111111111111111111111"))
        .with_value(U256::from(20000000000000));

    let calls = vec![tx1, tx2];

    Ok(())
}
