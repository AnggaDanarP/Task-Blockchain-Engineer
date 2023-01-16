// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

error ContractAlreadyHaveBrandName();
error ContractDoesntHaveBrandName();
error ContractNoExist();
error ContractAlreadyCreate();
error ContractAlreadyInactive();
error ContractAlreadyActive();
error CompanyNotOfficialStore();
error CompanyInactive();

contract OfficialStore is ERC721, Ownable {
    /*
     * ContractBrand is structure of brand and contract definition.
     * `name` will represent name of toko that assign as principle from Brand
     * `mainBrandAddress` will represent contract brand address
     * `district` will represent location of brand distribution
     * `expiredDate` will represent unit timestamp the brand will active
     * `active` will represent activation brand as principle official store
     */
    struct ContractBrand {
        string name;
        string district;
        address mainBrandAddress;
        uint256 expiredDate;
        bool active;
    }
    /*
     * _mainAddressBrand represent wallet address of brand assign
     * using bytes32 rather than string is more gass efisien
     * and make sure the data is under 32 characters
     */
    mapping(address => string) private _mainAddressBrand;

    // _contractBrandList represent list contract brand from the partners
    mapping(address => ContractBrand) private _contractBrandList;

    event BrandAddress(address indexed _from, string indexed _value);

    event BrandContract(address indexed _from, ContractBrand indexed _contractBrand);

    constructor() ERC721("OfficialStore", "OST") {}

    /*
     * setBrandContract will set an address as official store brand name
     * mainBrandAddress is destination the address assign as brand
     * brandName will represent brand name
     */
    function setBrandContract(address mainBrandAddress, string memory brandName)
        external
        onlyOwner
    {
        string memory _brandName = _mainAddressBrand[mainBrandAddress];
        if (!compareStrings(_brandName, "")) {
            revert ContractAlreadyHaveBrandName();
        }
        _mainAddressBrand[mainBrandAddress] = brandName;
        emit BrandAddress(mainBrandAddress, brandName);
    }

    /*
     * setContractOS will set an address as principle official store brand
     * contractAddress is destination the address assign as official store
     * contractBrandInfo will keep information of brand info
     */
    function setContractOS(
        address contractAddress,
        ContractBrand memory contractBrandInfo
    ) external onlyOwner {
        address _contractBrand = _contractBrandList[contractAddress].mainBrandAddress;
        if (_contractBrandExist(_contractBrand)) {
            revert ContractAlreadyCreate();
        }
        _contractBrandList[contractAddress] = contractBrandInfo;
        emit BrandContract(contractAddress, contractBrandInfo);
    }

    /*
     * enableContractOS will set active existing address to activate the brand official store
     * contractAddress is destination the address assign enable as the official store
     */
    function enableContractOS(address contractAddress) external onlyOwner {
        address _contractBrand = _contractBrandList[contractAddress].mainBrandAddress;
        bool brandStatus = _contractBrandList[contractAddress].active;
        if (!_contractBrandExist(_contractBrand)) {
            revert ContractNoExist();
        }
        if (brandStatus == true) {
            revert ContractAlreadyActive();
        }
        _contractBrandList[contractAddress].active = true;
    }

    /*
     * disableContractOS will set inactive existing address to activate the brand official store
     * contractAddress is destination the address to disable as the official store
     */
    function disableContractOS(address contractAddress) external onlyOwner {
        address _contractBrand = _contractBrandList[contractAddress].mainBrandAddress;
        bool brandStatus = _contractBrandList[contractAddress].active;
        if (!_contractBrandExist(_contractBrand)) {
            revert ContractNoExist();
        }
        if (brandStatus == false) {
            revert ContractAlreadyInactive();
        }
        _contractBrandList[contractAddress].active = false;
    }

    /*
     * extendContractOS will extend the contract as official store
     * contractAddress is destination the address assign to extend
     * ts is unix timestamp extend the contract address
     */
    function extendContractOS(address contractAddress, uint256 ts)
        external
        onlyOwner
    {
        address _contractBrand = _contractBrandList[contractAddress].mainBrandAddress;
        if (!_contractBrandExist(_contractBrand)) {
            revert ContractNoExist();
        }
        _contractBrandList[contractAddress].expiredDate = ts;
    }

    /*
     * getBrandFromAddress will show information brand
     * will return brand name information
     */
    function getBrandFromAddress(address brandAddress)
        public
        view
        returns (string memory brandName)
    {
        string memory _brandName = _mainAddressBrand[brandAddress];
        if (compareStrings(_brandName, "")) {
            revert ContractDoesntHaveBrandName();
        }
        return _mainAddressBrand[brandAddress];
    }

    /*
     * getContractBrandFromAddress will show information contract brand and principle
     */
    function getContractBrandFromAddress(address contractAddress)
        public
        view
        returns (ContractBrand memory)
    {
        address _contractBrand = _contractBrandList[contractAddress].mainBrandAddress;
        if (!_contractBrandExist(_contractBrand)) {
            revert ContractNoExist();
        }
        return _contractBrandList[contractAddress];
    }

    /*
     * isContractBrandActive will check contract address still active or not as official store.
     * contractAddress will represent the contract address of principle official store.
     * brandName will contain check what brand assign to the contract.
     * unixTimeNow will contain availability of time that assign.
     */
    function isContractBrandActive(
        address contractAddress,
        string memory brandName,
        uint256 unixTimeNow
    ) public view returns (string memory active) {
        string memory _mainBrandAddress = _mainAddressBrand[_contractBrandList[contractAddress].mainBrandAddress];
        bool _active = _contractBrandList[contractAddress].active;
        address _contractBrand = _contractBrandList[contractAddress].mainBrandAddress;

        if (!_contractBrandExist(_contractBrand)) {
            revert ContractNoExist();
        }
        if (!_active) {
            revert ContractAlreadyInactive();
        }

        if (!compareStrings(_mainBrandAddress, brandName)) {
            revert CompanyNotOfficialStore();
        }

        if (_contractBrandList[contractAddress].expiredDate < unixTimeNow) {
            revert CompanyInactive();
        }

        return "ACTIVE";
    }

    // compareStrings from the brand
    function compareStrings(string memory a, string memory b)
        public
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function _contractBrandExist(address _contractAddressBrand)
        private
        pure
        returns (bool)
    {
        if (_contractAddressBrand == address(0)) {
            return false;
        }
        return true;
    }
}
