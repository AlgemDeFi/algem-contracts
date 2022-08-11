import * as polkadotCryptoUtils from "@polkadot/util-crypto";
//import * as polkadotUtils from "@polkadot/util";


export function evmToPlm(addressInput: string): string {
//async function main(addressInput: string) {
    if (
        addressInput &&
        polkadotCryptoUtils.isEthereumAddress(addressInput)
    ) {
        return polkadotCryptoUtils.evmToAddress(addressInput);
    } else {
        return "invalid";
    }
}

const addressInput = "0x94C2C73f1Ea93DD3F2477c8B1A0c136D973dEee3";
/*
main(addressInput).catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
*/