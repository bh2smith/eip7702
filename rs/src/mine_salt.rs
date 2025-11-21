use alloy::primitives::{keccak256, Address, B256};
use rayon::prelude::*;
use std::env;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::Arc;
use std::time::Instant;

/// Computes the CREATE2 address given deployer, salt, and init code hash
fn compute_create2_address(deployer: Address, salt: B256, init_code_hash: B256) -> Address {
    let mut data = Vec::with_capacity(1 + 20 + 32 + 32);
    data.push(0xff);
    data.extend_from_slice(deployer.as_slice());
    data.extend_from_slice(salt.as_slice());
    data.extend_from_slice(init_code_hash.as_slice());
    
    let hash = keccak256(&data);
    Address::from_slice(&hash[12..])
}

/// Check if address starts with the given prefix (case-insensitive)
fn matches_prefix(address: &Address, prefix: &str) -> bool {
    let addr_hex = hex::encode(address.as_slice());
    addr_hex.to_lowercase().starts_with(&prefix.to_lowercase())
}

fn main() {
    let args: Vec<String> = env::args().collect();
    
    if args.len() < 4 {
        eprintln!("Usage: mine-salt <deployer_address> <init_code_hash> <prefix>");
        eprintln!("");
        eprintln!("Example:");
        eprintln!("  mine-salt 0x1234...5678 0xabcd...ef01 e0abc");
        eprintln!("");
        eprintln!("To get the init_code_hash:");
        eprintln!("  forge inspect EOAMultisend bytecode | tail -c +3 | xxd -r -p | sha3sum");
        eprintln!("  Or use: cast keccak $(forge inspect EOAMultisend bytecode)");
        std::process::exit(1);
    }

    let deployer: Address = args[1].parse().expect("Invalid deployer address");
    let init_code_hash: B256 = args[2].parse().expect("Invalid init code hash");
    let prefix = args[3].trim_start_matches("0x");
    
    // Validate prefix is valid hex
    if !prefix.chars().all(|c| c.is_ascii_hexdigit()) {
        eprintln!("Error: Prefix '{}' contains invalid hex characters", prefix);
        eprintln!("Valid hex characters are: 0-9, a-f, A-F");
        std::process::exit(1);
    }

    println!("🔍 Mining CREATE2 salt for address prefix: 0x{}", prefix);
    println!("📍 Deployer: {}", deployer);
    println!("🔨 Init code hash: {}", init_code_hash);
    println!("⛏️  Mining started...\n");

    let found = Arc::new(AtomicBool::new(false));
    let attempts = Arc::new(AtomicU64::new(0));
    let start_time = Instant::now();

    // Spawn a thread to print progress
    let attempts_clone = attempts.clone();
    let found_clone = found.clone();
    std::thread::spawn(move || {
        while !found_clone.load(Ordering::Relaxed) {
            std::thread::sleep(std::time::Duration::from_secs(5));
            let count = attempts_clone.load(Ordering::Relaxed);
            let elapsed = start_time.elapsed().as_secs_f64();
            let rate = count as f64 / elapsed;
            println!("⏳ Attempts: {} ({:.0} attempts/sec)", count, rate);
        }
    });

    // Use parallel iterator to try different salts
    let result = (0u64..u64::MAX).into_par_iter().find_map_any(|i| {
        if found.load(Ordering::Relaxed) {
            return None;
        }

        attempts.fetch_add(1, Ordering::Relaxed);
        
        // Create salt from counter
        let mut salt_bytes = [0u8; 32];
        salt_bytes[24..32].copy_from_slice(&i.to_be_bytes());
        let salt = B256::from(salt_bytes);
        
        let address = compute_create2_address(deployer, salt, init_code_hash);
        
        if matches_prefix(&address, prefix) {
            found.store(true, Ordering::Relaxed);
            Some((salt, address))
        } else {
            None
        }
    });

    if let Some((salt, address)) = result {
        let elapsed = start_time.elapsed();
        let total_attempts = attempts.load(Ordering::Relaxed);
        
        println!("\n✅ Found matching address!");
        println!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        println!("Salt:    {}", salt);
        println!("Address: {}", address);
        println!("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        println!("⏱️  Time: {:.2}s", elapsed.as_secs_f64());
        println!("🔢 Attempts: {}", total_attempts);
        println!("\nAdd this to your deployment script:");
        println!("bytes32 public constant SALT = {};", salt);
    } else {
        println!("❌ Mining stopped without finding a match");
    }
}

