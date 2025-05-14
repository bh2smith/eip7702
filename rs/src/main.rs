use alloy::{
    eips::eip7702::Authorization,
    network::{TransactionBuilder, TransactionBuilder7702},
    primitives::{Address, Bytes, TxKind, U256, address},
    providers::{Provider, ProviderBuilder},
    rpc::types::TransactionRequest,
    signers::{SignerSync, local::PrivateKeySigner},
    sol,
};
use bytes::{BufMut, BytesMut};
use eyre::Result;
use std::env;
use std::str::FromStr;

sol!(
    #[allow(missing_docs)]
    #[sol(rpc)]
    EOAMultisend,
    "../out/EOAMultisend.sol/EOAMultisend.json"
);

const EOA_MULTISEND_ADDRESS: Address = address!("0xDa51eBfBb740D2183e91FAf762666B169A1A9a62");

async fn eoa_multisend(pk: PrivateKeySigner, calls: Vec<TransactionRequest>) -> Result<()> {
    let rpc_url = "https://sepolia.drpc.org".parse()?;
    let provider = ProviderBuilder::new()
        .wallet(pk.clone())
        .connect_http(rpc_url);

    let contract = EOAMultisend::new(EOA_MULTISEND_ADDRESS, provider.clone());

    let authorization = Authorization {
        chain_id: U256::from(11155111),
        address: *contract.address(),
        nonce: provider.get_transaction_count(pk.address()).await?,
    };

    let signature = pk.sign_hash_sync(&authorization.signature_hash())?;
    let signed_authorization = authorization.into_signed(signature);

    let batched = pack_multisend(&calls)?;

    let call = contract.execute_0(batched);
    let execute_calldata = call.calldata().to_owned();

    let tx = TransactionRequest::default()
        .with_to(pk.address())
        .with_authorization_list(vec![signed_authorization])
        .with_input(execute_calldata);

    // Send the transaction and wait for the broadcast.
    let pending_tx = provider.send_transaction(tx).await?;

    println!("Pending transaction... {}", pending_tx.tx_hash());

    let receipt = pending_tx.get_receipt().await?;

    let etherscan_url = String::from("https://sepolia.etherscan.io/tx/");
    println!(
        "  Tx Receipt: {}",
        etherscan_url + &receipt.transaction_hash.to_string()
    );

    Ok(())
}

/// Encode a list of EOA-style txs for MultiSend/MultiSendCallOnly.
fn pack_multisend(calls: &[TransactionRequest]) -> eyre::Result<Bytes> {
    let mut out = BytesMut::new();

    for tx in calls {
        // operation ─ normal CALL
        out.put_u8(0);

        // to ─ 20 bytes (error if missing)
        let to = match tx.to.as_ref() {
            Some(TxKind::Call(addr)) => addr,
            _ => return Err(eyre::eyre!("Tx is missing `to` address")),
        };
        out.extend_from_slice(to.as_slice());

        // value ─ 32 bytes big-endian
        let value: U256 = tx.value.unwrap_or_default();
        out.extend_from_slice(&value.to_be_bytes::<32>());

        // data length & data
        let data: Bytes = tx
            .input
            .input // first try the “input” field
            .clone()
            .or_else(|| tx.input.data.clone()) // else fall back to “data”
            .unwrap_or_default(); // or empty
        out.extend_from_slice(&U256::from(data.len()).to_be_bytes::<32>());
        out.extend_from_slice(&data);
    }

    Ok(Bytes::from(out.freeze()))
}

#[tokio::main]
async fn main() -> Result<()> {
    let private_key: PrivateKeySigner = match env::var("PK") {
        Ok(pk) => PrivateKeySigner::from_str(pk.as_str())?,
        Err(_) => PrivateKeySigner::from_str(
            "0xe4dc8cbe94cbc139084c9c7adc5c2a829d3246f76282679e0c067147a47eb3f8",
        )?,
    };

    let tx1 = TransactionRequest::default()
        .with_to(Address::ZERO)
        .with_value(U256::from(10000000000000_i64));

    let tx2 = TransactionRequest::default()
        .with_to(address!("0x1111111111111111111111111111111111111111"))
        .with_value(U256::from(20000000000000_i64));

    let calls = vec![tx1, tx2];

    eoa_multisend(private_key, calls).await?;

    Ok(())
}
