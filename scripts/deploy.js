const hre = require("hardhat");

async function main() {
    console.log("🚀 Starting CoinSight Smart Contract Deployment...\n");

    // Get deployer account
    const [deployer] = await hre.ethers.getSigners();
    console.log("📍 Deploying contracts with account:", deployer.address);

    const balance = await hre.ethers.provider.getBalance(deployer.address);
    console.log("💰 Account balance:", hre.ethers.formatEther(balance), "ETH\n");

    // Deploy AgentRegistry
    console.log("📝 Deploying AgentRegistry...");
    const AgentRegistry = await hre.ethers.getContractFactory("AgentRegistry");
    const agentRegistry = await AgentRegistry.deploy();
    await agentRegistry.waitForDeployment();
    const agentRegistryAddress = await agentRegistry.getAddress();

    console.log("✅ AgentRegistry deployed to:", agentRegistryAddress);

    // Deploy ResearchMarketplace
    console.log("\n📝 Deploying ResearchMarketplace...");
    const ResearchMarketplace = await hre.ethers.getContractFactory("ResearchMarketplace");
    const marketplace = await ResearchMarketplace.deploy();
    await marketplace.waitForDeployment();
    const marketplaceAddress = await marketplace.getAddress();

    console.log("✅ ResearchMarketplace deployed to:", marketplaceAddress);

    // Link contracts
    console.log("\n🔗 Linking contracts...");
    const tx = await agentRegistry.setMarketplaceContract(marketplaceAddress);
    await tx.wait();
    console.log("✅ AgentRegistry linked to ResearchMarketplace");

    // Print deployment summary
    console.log("\n" + "=".repeat(60));
    console.log("📊 DEPLOYMENT SUMMARY");
    console.log("=".repeat(60));
    console.log("Network:", hre.network.name);
    console.log("Deployer:", deployer.address);
    console.log("\n📄 Contract Addresses:");
    console.log("  AgentRegistry:", agentRegistryAddress);
    console.log("  ResearchMarketplace:", marketplaceAddress);
    console.log("=".repeat(60));

    // Save deployment info
    const fs = require("fs");
    const deploymentInfo = {
        network: hre.network.name,
        deployer: deployer.address,
        timestamp: new Date().toISOString(),
        contracts: {
            AgentRegistry: agentRegistryAddress,
            ResearchMarketplace: marketplaceAddress,
        },
    };

    const deploymentsDir = "./deployments";
    if (!fs.existsSync(deploymentsDir)) {
        fs.mkdirSync(deploymentsDir);
    }

    fs.writeFileSync(
        `${deploymentsDir}/${hre.network.name}.json`,
        JSON.stringify(deploymentInfo, null, 2)
    );

    console.log(`\n💾 Deployment info saved to: ${deploymentsDir}/${hre.network.name}.json`);

    // Verification instructions
    if (hre.network.name !== "hardhat" && hre.network.name !== "localhost") {
        console.log("\n🔍 To verify contracts on Etherscan, run:");
        console.log(`npx hardhat verify --network ${hre.network.name} ${agentRegistryAddress}`);
        console.log(`npx hardhat verify --network ${hre.network.name} ${marketplaceAddress}`);
    }

    console.log("\n✨ Deployment completed successfully!\n");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
