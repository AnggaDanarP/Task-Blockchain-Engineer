// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

error ContractAlreadyHaveBrandName();
error ContractDoesntHaveBrandName();
error ContractNoExist();
error ContractAlreadyCreate();
error ContractAlreadyInactive();
error ContractAlreadyActive();
error CompanyNotOfficialStore();
error TimeIsIncorect();

contract OfficialStore {
    address private owner;
    /*
     * ContractBrand is structure of brand and contract definition.
     * `name` will represent name of toko that assign as principle from Brand
     * `mainBrandAddress` will represent contract brand address
     * `district` will represent location of brand distribution
     * `expiredDate` will represent unit timestamp the brand will active
     * `active` will represent activation brand as principle official store
     */
    struct ContractBrand {
        bytes32 name;
        bytes32 district;
        uint256 expiredDate;
        address mainBrandAddress;
        bool active;
    }
    /*
     * _mainAddressBrand represent wallet address of brand assign
     * using bytes32 rather than string is more gass efisien
     * and make sure the data is under 32 characters
     */
    mapping(address => bytes32) private _mainAddressBrand;

    // _contractBrandList represent list contract brand from the partners
    mapping(address => ContractBrand) private _contractBrandList;

    event BrandAddress(address indexed _from, string indexed _value);
    event BrandContract(
        address indexed _from,
        ContractBrand indexed _contractBrand
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier contractExist(address contractBrand) {
        address _contractBrand = _contractBrandList[contractBrand].mainBrandAddress;
        if (_contractBrandExist(_contractBrand)) {
            revert ContractNoExist();
        }
        _;
    }

    /*
     * setBrandContract will set an address as official store brand name
     * mainBrandAddress is destination the address assign as brand
     * brandName will represent brand name
     */
    function setBrandContract(address mainBrandAddress, string memory brandName)
        external
        onlyOwner
    {
        bytes32 _brandName = _mainAddressBrand[mainBrandAddress];
        if (_brandName[0] != 0) {
            revert ContractAlreadyHaveBrandName();
        }
        bytes32 newInput = stringToBytes32(brandName);
        _mainAddressBrand[mainBrandAddress] = newInput;
        emit BrandAddress(mainBrandAddress, brandName);
    }

    /*
     * setContractOS will set an address as principle official store brand
     * contractAddress is destination the address assign as official store
     * contractBrandInfo will keep information of brand info
     */
    function setContractOS(
        address contractAddress,
        string memory nameBrand,
        string memory districtBrand,
        uint256 expiredDateBrand,
        address mainAddressBrand,
        bool isActive
    ) external onlyOwner {
        address _contractBrand = _contractBrandList[contractAddress].mainBrandAddress;
        if (!_contractBrandExist(_contractBrand)) {
            revert ContractAlreadyCreate();
        }
        ContractBrand memory newContractBrand = ContractBrand({
            name: stringToBytes32(nameBrand),
            district: stringToBytes32(districtBrand),
            expiredDate: expiredDateBrand + block.timestamp,
            mainBrandAddress: mainAddressBrand,
            active: isActive
        });
        _contractBrandList[contractAddress] = newContractBrand;
        emit BrandContract(contractAddress, newContractBrand);
    }

    /*
     * enableContractOS will set active existing address to activate the brand official store
     * contractAddress is destination the address assign enable as the official store
     */
    function enableContractOS(address contractAddress)
        external
        onlyOwner
        contractExist(contractAddress)
    {
        bool brandStatus = _contractBrandList[contractAddress].active;
        if (brandStatus == true) {
            revert ContractAlreadyActive();
        }
        _contractBrandList[contractAddress].active = true;
    }

    /*
     * disableContractOS will set inactive existing address to activate the brand official store
     * contractAddress is destination the address to disable as the official store
     */
    function disableContractOS(address contractAddress)
        external
        onlyOwner
        contractExist(contractAddress)
    {
        bool brandStatus = _contractBrandList[contractAddress].active;
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
        contractExist(contractAddress)
    {
        uint256 currentTime = block.timestamp;
        if (ts <= currentTime) {
            revert TimeIsIncorect();
        }
        _contractBrandList[contractAddress].expiredDate = uint64(ts);
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
        bytes32 _brandName = _mainAddressBrand[brandAddress];
        if (_brandName[0] == 0) {
            revert ContractDoesntHaveBrandName();
        }
        return bytes32ToString(_brandName);
    }

    /*
     * getContractBrandFromAddress will show information contract brand and principle
     */
    function getContractBrandFromAddress(address contractAddress)
        public
        view
        contractExist(contractAddress)
        returns (ContractBrand memory)
    {
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
    )
        public
        view
        contractExist(contractAddress)
        returns (string memory active)
    {
        bytes32 _mainBrandAddress = _mainAddressBrand[
            _contractBrandList[contractAddress].mainBrandAddress
        ];
        bytes32 _brandName = stringToBytes32(brandName);
        bool _active = _contractBrandList[contractAddress].active;
        uint256 _expiredDate = _contractBrandList[contractAddress].expiredDate;

        if (_mainBrandAddress != _brandName) {
            revert CompanyNotOfficialStore();
        }

        if (!_active) {
            return "INACTIVE";
        }

        if (_expiredDate < unixTimeNow) {
            return "INACTIVE";
        }

        return "ACTIVE";
    }

    function _contractBrandExist(address _contractAddressBrand)
        private
        pure
        returns (bool)
    {
        return _contractAddressBrand == address(0);
    }

    function stringToBytes32(string memory source)
        private
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 _bytes32)
        private
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}
