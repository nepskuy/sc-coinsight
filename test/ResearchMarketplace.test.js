const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time, loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("ResearchMarketplace", function () {
    // Deploy fixture
    async function deployMarketplaceFixture() {
        const [owner, requester, researcher1, researcher2] = await ethers.getSigners();

        const ResearchMarketplace = await ethers.getContractFactory("ResearchMarketplace");
        const marketplace = await ResearchMarketplace.deploy();

        const minBounty = await marketplace.minBounty();
        const minStake = await marketplace.minStake();

        return { marketplace, owner, requester, researcher1, researcher2, minBounty, minStake };
    }

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            const { marketplace, owner } = await loadFixture(deployMarketplaceFixture);
            expect(await marketplace.owner()).to.equal(owner.address);
        });

        it("Should set correct initial values", async function () {
            const { marketplace } = await loadFixture(deployMarketplaceFixture);
            expect(await marketplace.requestCount()).to.equal(0);
            expect(await marketplace.reportCount()).to.equal(0);
            expect(await marketplace.platformFeePercentage()).to.equal(5);
        });
    });

    describe("Research Requests", function () {
        it("Should create a research request", async function () {
            const { marketplace, requester, minBounty } = await loadFixture(deployMarketplaceFixture);

            const query = "Analyze Uniswap V3 TVL trends";
            const deadline = (await time.latest()) + 86400; // 1 day from now

            await expect(
                marketplace.connect(requester).createRequest(query, deadline, {
                    value: minBounty,
                })
            )
                .to.emit(marketplace, "RequestCreated")
                .withArgs(0, requester.address, query, minBounty, deadline);

            const request = await marketplace.getRequest(0);
            expect(request.requester).to.equal(requester.address);
            expect(request.query).to.equal(query);
            expect(request.bounty).to.equal(minBounty);
        });

        it("Should fail if bounty is below minimum", async function () {
            const { marketplace, requester } = await loadFixture(deployMarketplaceFixture);

            const query = "Test query";
            const deadline = (await time.latest()) + 86400;

            await expect(
                marketplace.connect(requester).createRequest(query, deadline, {
                    value: ethers.parseEther("0.001"),
                })
            ).to.be.revertedWith("Bounty below minimum");
        });

        it("Should fail if deadline is in the past", async function () {
            const { marketplace, requester, minBounty } = await loadFixture(deployMarketplaceFixture);

            const query = "Test query";
            const deadline = (await time.latest()) - 1; // Past

            await expect(
                marketplace.connect(requester).createRequest(query, deadline, {
                    value: minBounty,
                })
            ).to.be.revertedWith("Invalid deadline");
        });
    });

    describe("Report Submission", function () {
        it("Should submit a research report", async function () {
            const { marketplace, requester, researcher1, minBounty, minStake } =
                await loadFixture(deployMarketplaceFixture);

            // Create request
            const query = "Analyze protocol";
            const deadline = (await time.latest()) + 86400;
            await marketplace.connect(requester).createRequest(query, deadline, {
                value: minBounty,
            });

            // Submit report
            const ipfsHash = "QmTest123456789";
            const commitment = ethers.keccak256(ethers.toUtf8Bytes("findings"));

            await expect(
                marketplace.connect(researcher1).submitReport(0, ipfsHash, commitment, {
                    value: minStake,
                })
            )
                .to.emit(marketplace, "ReportSubmitted")
                .withArgs(0, 0, researcher1.address, ipfsHash);

            const report = await marketplace.getReport(0);
            expect(report.researcher).to.equal(researcher1.address);
            expect(report.ipfsHash).to.equal(ipfsHash);
        });

        it("Should fail if stake is below minimum", async function () {
            const { marketplace, requester, researcher1, minBounty } =
                await loadFixture(deployMarketplaceFixture);

            const query = "Analyze protocol";
            const deadline = (await time.latest()) + 86400;
            await marketplace.connect(requester).createRequest(query, deadline, {
                value: minBounty,
            });

            await expect(
                marketplace.connect(researcher1).submitReport(0, "QmTest", ethers.keccak256(ethers.toUtf8Bytes("test")), {
                    value: ethers.parseEther("0.001"),
                })
            ).to.be.revertedWith("Stake below minimum");
        });

        it("Should fail if deadline passed", async function () {
            const { marketplace, requester, researcher1, minBounty, minStake } =
                await loadFixture(deployMarketplaceFixture);

            const deadline = (await time.latest()) + 100;
            await marketplace.connect(requester).createRequest("Test", deadline, {
                value: minBounty,
            });

            // Advance time past deadline
            await time.increase(200);

            await expect(
                marketplace.connect(researcher1).submitReport(0, "QmTest", ethers.keccak256(ethers.toUtf8Bytes("test")), {
                    value: minStake,
                })
            ).to.be.revertedWith("Deadline passed");
        });
    });

    describe("Report Selection", function () {
        it("Should select a winning report", async function () {
            const { marketplace, requester, researcher1, minBounty, minStake } =
                await loadFixture(deployMarketplaceFixture);

            // Create request
            const deadline = (await time.latest()) + 86400;
            await marketplace.connect(requester).createRequest("Test query", deadline, {
                value: minBounty,
            });

            // Submit report
            await marketplace.connect(researcher1).submitReport(
                0,
                "QmTest",
                ethers.keccak256(ethers.toUtf8Bytes("findings")),
                { value: minStake }
            );

            // Get initial balance
            const initialBalance = await ethers.provider.getBalance(researcher1.address);

            // Select report
            await expect(marketplace.connect(requester).selectReport(0, 0))
                .to.emit(marketplace, "ReportSelected");

            // Check researcher received reward + stake
            const finalBalance = await ethers.provider.getBalance(researcher1.address);
            expect(finalBalance).to.be.gt(initialBalance);

            // Check request is completed
            const request = await marketplace.getRequest(0);
            expect(request.status).to.equal(2); // Completed
        });

        it("Should fail if not requester", async function () {
            const { marketplace, requester, researcher1, researcher2, minBounty, minStake } =
                await loadFixture(deployMarketplaceFixture);

            const deadline = (await time.latest()) + 86400;
            await marketplace.connect(requester).createRequest("Test", deadline, {
                value: minBounty,
            });

            await marketplace.connect(researcher1).submitReport(
                0,
                "QmTest",
                ethers.keccak256(ethers.toUtf8Bytes("test")),
                { value: minStake }
            );

            await expect(
                marketplace.connect(researcher2).selectReport(0, 0)
            ).to.be.revertedWith("Not the requester");
        });
    });

    describe("Stake Return", function () {
        it("Should return stake to non-selected researchers", async function () {
            const { marketplace, requester, researcher1, researcher2, minBounty, minStake } =
                await loadFixture(deployMarketplaceFixture);

            // Create request
            const deadline = (await time.latest()) + 86400;
            await marketplace.connect(requester).createRequest("Test", deadline, {
                value: minBounty,
            });

            // Submit two reports
            await marketplace.connect(researcher1).submitReport(
                0,
                "QmTest1",
                ethers.keccak256(ethers.toUtf8Bytes("test1")),
                { value: minStake }
            );

            await marketplace.connect(researcher2).submitReport(
                0,
                "QmTest2",
                ethers.keccak256(ethers.toUtf8Bytes("test2")),
                { value: minStake }
            );

            // Select first report
            await marketplace.connect(requester).selectReport(0, 0);

            // Second researcher should be able to return stake
            const initialBalance = await ethers.provider.getBalance(researcher2.address);
            await marketplace.connect(researcher2).returnStake(1);
            const finalBalance = await ethers.provider.getBalance(researcher2.address);

            expect(finalBalance).to.be.gt(initialBalance);
        });
    });

    describe("Admin Functions", function () {
        it("Should allow owner to update platform fee", async function () {
            const { marketplace, owner } = await loadFixture(deployMarketplaceFixture);

            await marketplace.connect(owner).setPlatformFee(7);
            expect(await marketplace.platformFeePercentage()).to.equal(7);
        });

        it("Should fail if non-owner tries to update fee", async function () {
            const { marketplace, requester } = await loadFixture(deployMarketplaceFixture);

            await expect(
                marketplace.connect(requester).setPlatformFee(7)
            ).to.be.revertedWithCustomError(marketplace, "OwnableUnauthorizedAccount");
        });

        it("Should allow owner to pause/unpause", async function () {
            const { marketplace, owner, requester, minBounty } =
                await loadFixture(deployMarketplaceFixture);

            await marketplace.connect(owner).pause();

            const deadline = (await time.latest()) + 86400;
            await expect(
                marketplace.connect(requester).createRequest("Test", deadline, {
                    value: minBounty,
                })
            ).to.be.revertedWithCustomError(marketplace, "EnforcedPause");

            await marketplace.connect(owner).unpause();

            await expect(
                marketplace.connect(requester).createRequest("Test", deadline, {
                    value: minBounty,
                })
            ).to.emit(marketplace, "RequestCreated");
        });
    });
});
