pragma solidity ^0.5.11;

contract RemoteHealthcare{
    // Health Care Provider Details
    
    address payable public healthcare_provider_address;
    string public healthcare_provider_name;
    
    constructor() public {
        healthcare_provider_address = msg.sender;
        healthcare_provider_name = "Health Care Provider";
    }
    
    function UpdateHealthCareProviderName(string memory _name) public {
        healthcare_provider_name = _name;
    }
    
    // Register Patients
    
    enum Gender{Male, Female}
    
    struct Patient {
        uint256 id;
        string name;
        uint256 dob;
        Gender gender;
    }
   
    uint256 public number_of_patients = 0; 
    uint256 patient_id_generator = 1; 
    
    mapping (address => Patient) registered_patients;
    mapping (address => bool) is_patient_registered;
    
    function Add_Patient(address _address, string memory _name, uint256  _dob, Gender  _gender) public {
        require(!is_patient_registered[_address] && !is_doctor_registered[_address] && _address != healthcare_provider_address);
        Patient memory new_patient = Patient(patient_id_generator, _name, _dob, _gender);
        patient_id_generator++;
        registered_patients[_address] = new_patient;
        is_patient_registered[_address] = true; 
        number_of_patients++;
    }
    
    function Update_Patient_Info(address _address, string memory _name, uint256  _dob, Gender  _gender) public {
        require(is_patient_registered[_address]);
        registered_patients[_address].name = _name;
        registered_patients[_address].dob = _dob;
        registered_patients[_address].gender = _gender;
    }
        
    function Remove_Patient(address _address) public {
        require(is_patient_registered[_address]);
        delete registered_patients[_address];
        is_patient_registered[_address] = false;
        number_of_patients--;
    }    
    
    function Get_Patient(address _address) public view returns (uint256, string memory, uint256, Gender){
        require(is_patient_registered[_address]);
        return (registered_patients[_address].id, registered_patients[_address].name, registered_patients[_address].dob, 
            registered_patients[_address].gender);
    }   
    
    function Is_Patient(address _address) public view returns (bool){
        return is_patient_registered[_address];
    }
    
     // Register Doctors
     
    struct Doctor {
        uint256 id;
        string name;
        string qualification;
    }
   
    uint256 public number_of_doctors = 0; 
    uint256 doctor_id_generator = 1; 
    address[] doctors_list;
    
    mapping (address => Doctor) registered_doctors;
    mapping (address => bool) is_doctor_registered;
    
    function Add_Doctor(address _address, string memory _name, string memory _qualification) public {
        require(!is_patient_registered[_address] && !is_doctor_registered[_address] && _address != healthcare_provider_address);
        Doctor memory new_doctor = Doctor(doctor_id_generator, _name, _qualification);
        doctor_id_generator++;
        registered_doctors[_address] = new_doctor;
        is_doctor_registered[_address] = true; 
        number_of_doctors++;
        doctors_list.push(_address);
    }
    
    function Update_Doctor_Info(address _address, string memory _name, string memory _qualification) public {
        require(is_doctor_registered[_address]);
        registered_doctors[_address].name = _name;
        registered_doctors[_address].qualification = _qualification;
    }
        
    function Remove_Doctor(address _address) public {
        require(is_doctor_registered[_address]);
        delete registered_doctors[_address];
        is_doctor_registered[_address] = false;
        number_of_doctors--;
    }    
    
    function Get_Doctor(address _address) public view returns (uint256, string memory, string memory){
        require(is_doctor_registered[_address]);
        return (registered_doctors[_address].id, registered_doctors[_address].name, registered_doctors[_address].qualification);
    }
    
    
    function Is_Doctor(address _address) public view returns (bool){
        return is_doctor_registered[_address];
    }
    
    
    function Get_Role() public view returns (string memory){
        if (msg.sender == healthcare_provider_address)
            return "healthcare_provider";
        else if (is_patient_registered[msg.sender])
            return "patient";
        else if (is_doctor_registered[msg.sender])
            return "doctor";
        return "none";
    }
     
    uint256 public number_cases = 0;
    uint256 public case_id_generator = 1;
    
    
    struct Case {
        uint256 id;
        string status;
        string symptoms;
        string diagnosys;
        uint256 fees;
        address patient_address;
        address payable doctor_address;
    }
    
    mapping (uint256 => Case) case_map;
    mapping (uint256 => bool) is_case;
    mapping (address => uint256[]) doctor_cases;
    mapping (address => uint256[]) patient_cases;
    uint256[] public hcp_cases;
    mapping (address => uint256) doctor_open_cases;
    mapping (address => uint256) patient_open_cases;
    mapping (address => uint256) patient_diagnosed_cases;
    uint256 public hcp_open_cases;
    uint256 public hcp_pending_cases;
    uint256 public hcp_paid_cases;
    
    function Create_Case(string memory _symptoms) public {
       if (is_patient_registered[msg.sender]) {
           uint256 case_id = case_id_generator;
           Case memory new_case = Case(case_id, "Submitted", _symptoms, "", 0, msg.sender, address(0));
           case_id_generator++;
           
           patient_cases[msg.sender].push(case_id);
           hcp_cases.push(case_id);
           patient_open_cases[msg.sender] += 1;
           hcp_open_cases += 1;
           case_map[case_id] = new_case;
           is_case[case_id] = true;
           number_cases++;
           
       } 
    }
    
    function Assign_Case(uint256 _case_id, address payable _doctor) public {
        if (msg.sender == healthcare_provider_address && is_doctor_registered[_doctor] && is_case[_case_id]){
            case_map[_case_id].doctor_address = _doctor;
            case_map[_case_id].status = "Assigned";
            doctor_cases[_doctor].push(_case_id);
            doctor_open_cases[_doctor] += 1;
            hcp_open_cases -= 1;
        }
    }
    
    function Diagnose_Case(uint256 _case_id, string memory _diagnosys, uint256 _fees) public {
        if (is_doctor_registered[msg.sender] && is_case[_case_id] && case_map[_case_id].doctor_address == msg.sender){
           case_map[_case_id].diagnosys = _diagnosys;
           case_map[_case_id].status = "Diagnosed";
           case_map[_case_id].fees = _fees;
           doctor_open_cases[msg.sender] -= 1;
           patient_diagnosed_cases[case_map[_case_id].patient_address] += 1;
           hcp_pending_cases += 1;
        }
    }
    
    function Get_Patient_Open_Cases() public view returns (uint256[] memory) {
        uint256[] memory open_cases;
        uint256 added = 0;
        
        if (is_patient_registered[msg.sender] && patient_open_cases[msg.sender] > 0){
            open_cases = new uint256[](patient_open_cases[msg.sender]);
            for (uint256 i = 0; i < patient_cases[msg.sender].length; i++){
                if (keccak256(abi.encodePacked(case_map[patient_cases[msg.sender][i]].status)) != keccak256(abi.encodePacked("Paid"))){
                    open_cases[added] = patient_cases[msg.sender][i];
                    added++;
                }
            }
        }
        
        return open_cases;
    }
    
    function Get_Doctor_Open_Cases() public view returns (uint256[] memory) {
        uint256[] memory open_cases;
        uint256 added = 0;
        
        if (is_doctor_registered[msg.sender] && doctor_open_cases[msg.sender] > 0){
            open_cases = new uint256[](doctor_open_cases[msg.sender]);
            uint256[] memory cases = doctor_cases[msg.sender]; 
            for (uint256 i; i < cases.length; i++){
                if (keccak256(abi.encodePacked(case_map[doctor_cases[msg.sender][i]].status)) == keccak256(abi.encodePacked("Assigned"))){
                    open_cases[added] = doctor_cases[msg.sender][i];
                    added++;
                }
            }
        }
        
        return open_cases;
    }
    
    
    function Get_HCP_Open_Cases() public view returns (uint256[] memory) {
        uint256[] memory open_cases;
        uint256 added = 0;
        
        if (msg.sender == healthcare_provider_address && hcp_open_cases > 0){
            open_cases = new uint256[](hcp_open_cases);
            uint256[] memory cases = hcp_cases; 
            for (uint256 i = 0; i < cases.length; i++){
                if (keccak256(abi.encodePacked(case_map[hcp_cases[i]].status)) == keccak256(abi.encodePacked("Submitted"))){
                    open_cases[added] = hcp_cases[i];
                    added++;
                }
            }
        }
        
        return open_cases;
    }
    
    function Get_Case(uint256 _case_id) public view returns (uint256, string memory, string memory, string memory, uint256, address, address) {
       if (is_case[_case_id] && (msg.sender == healthcare_provider_address || msg.sender == case_map[_case_id].patient_address 
                ||is_doctor_registered[msg.sender])){
           
           return (case_map[_case_id].id, case_map[_case_id].status, case_map[_case_id].symptoms, case_map[_case_id].diagnosys, 
                    case_map[_case_id].fees, case_map[_case_id].patient_address, case_map[_case_id].doctor_address);
       }
    }
    
    function Get_Doctors() public view returns (address[] memory) {
        address[] memory doctors = new address[](number_of_doctors);
        
        if (msg.sender == healthcare_provider_address){
            uint256 added = 0;
            for (uint256 i = 0; i < doctors_list.length; i++){
                if (is_doctor_registered[doctors_list[i]]){
                    doctors[added] = doctors_list[i];
                    added++;
                }
            }
        }
        
        return doctors;
    }
    
    function Make_Payment(uint256 _case_id) public payable{
        require( is_patient_registered[msg.sender] && is_case[_case_id] && case_map[_case_id].patient_address == msg.sender);
        address payable doctor = case_map[_case_id].doctor_address;
        uint256 amount = case_map[_case_id].fees * 1E18;
        
        require (msg.value >= amount && msg.sender.balance >= msg.value && is_doctor_registered[doctor]);
        uint256 hcp_fees = (1 ether)/4;
        uint256 doctor_fees = amount - hcp_fees;
        
        healthcare_provider_address.transfer(hcp_fees);
        doctor.transfer(doctor_fees);
        if (msg.value - amount > 0)
            msg.sender.transfer(msg.value - amount);
            
        case_map[_case_id].status = "Paid";
        patient_open_cases[msg.sender] -= 1;    
        hcp_paid_cases += 1;
        hcp_pending_cases -= 1;
    }
    
    function Get_Medical_History() public view returns (uint256[] memory) {
        uint256[] memory doagnosed_cases;
        uint256 added = 0;
        
        if (is_patient_registered[msg.sender] && patient_diagnosed_cases[msg.sender] > 0){
            doagnosed_cases = new uint256[](patient_diagnosed_cases[msg.sender]);
            for (uint256 i = 0; i < patient_cases[msg.sender].length; i++){
                if (keccak256(abi.encodePacked(case_map[patient_cases[msg.sender][i]].status)) == keccak256(abi.encodePacked("Diagnosed")) || 
                    keccak256(abi.encodePacked(case_map[patient_cases[msg.sender][i]].status)) == keccak256(abi.encodePacked("Paid"))){
                    doagnosed_cases[added] = patient_cases[msg.sender][i];
                    added++;
                }
            }
        }
        
        return doagnosed_cases;
    }
    
    function Get_Medical_History_By_Case(uint256 _case_id) public view returns (uint256[] memory) {
        uint256[] memory diagnosed_cases;
        uint256 added = 0;
        
        if (is_doctor_registered[msg.sender] && is_case[_case_id] && case_map[_case_id].doctor_address == msg.sender 
                && patient_diagnosed_cases[case_map[_case_id].patient_address] > 0){
            address patient = case_map[_case_id].patient_address;
            diagnosed_cases = new uint256[](patient_diagnosed_cases[patient]);
            for (uint256 i = 0; i < patient_cases[patient].length; i++){
                if (keccak256(abi.encodePacked(case_map[patient_cases[patient][i]].status)) == keccak256(abi.encodePacked("Diagnosed")) || 
                    keccak256(abi.encodePacked(case_map[patient_cases[patient][i]].status)) == keccak256(abi.encodePacked("Paid"))){
                    diagnosed_cases[added] = patient_cases[patient][i];
                    added++;
                }
            }
        }
        
        return diagnosed_cases;
    }
    
    function Get_Patient_Name(address _address) public view returns (string memory){
        if (is_patient_registered[_address])
            return registered_patients[_address].name;
        else
            return "";
    }
    
    function Get_Doctor_Name(address _address) public view returns (string memory){
        if (is_doctor_registered[_address])
            return registered_doctors[_address].name;
        else
            return "";
    }
    
    function Get_HCP_Pending_Cases() public view returns (uint256[] memory) {
        uint256[] memory pending_cases;
        uint256 added = 0;
        
        if (msg.sender == healthcare_provider_address && hcp_pending_cases > 0){
            pending_cases = new uint256[](hcp_pending_cases);
            uint256[] memory cases = hcp_cases; 
            for (uint256 i = 0; i < cases.length; i++){
                if (keccak256(abi.encodePacked(case_map[hcp_cases[i]].status)) == keccak256(abi.encodePacked("Diagnosed"))){
                    pending_cases[added] = hcp_cases[i];
                    added++;
                }
            }
        }
        
        return pending_cases;
    }
    
    function Get_HCP_Paid_Cases() public view returns (uint256[] memory) {
        uint256[] memory paid_cases;
        uint256 added = 0;
        
        if (msg.sender == healthcare_provider_address && hcp_paid_cases > 0){
            paid_cases = new uint256[](hcp_paid_cases);
            uint256[] memory cases = hcp_cases; 
            for (uint256 i = 0; i < cases.length; i++){
                if (keccak256(abi.encodePacked(case_map[hcp_cases[i]].status)) == keccak256(abi.encodePacked("Paid"))){
                    paid_cases[added] = hcp_cases[i];
                    added++;
                }
            }
        }
        
        return paid_cases;
    }
    
    
}