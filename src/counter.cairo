use starknet::ContractAddress;

#[starknet::interface]
trait ICounter <TContractState> {
    fn get_counter(self: @TContractState) -> u32;
    fn increase_counter(ref self:TContractState);
}

#[starknet::interface]
trait IKillSwitch<TContractState> {
    fn is_active(self: @TContractState) -> bool;
}

#[starknet::contract]
mod Counter {
    use super::ICounter;
    use super::IKillSwitchDispatcher;
    use super::IKillSwitchDispatcherTrait;
    use starknet::ContractAddress;
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

   
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableCamelOnlyImpl =
        OwnableComponent::OwnableCamelOnlyImpl<ContractState>;
    impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // #[storage]
    // struct Storage {
    //     #[substorage(v0)]
    //     ownable: OwnableComponent::Storage
    // }

    // #[event]
    // #[derive(Drop, starknet::Event)]
    // enum Event {
    //     #[flat]
    //     OwnableEvent: OwnableComponent::Event
    // }

    // #[constructor]
    // fn constructor(ref self: ContractState, owner: ContractAddress) {
    //     // Set the initial owner of the contract
    //     self.ownable.initializer(owner);
    // }
   


    #[storage]
    struct Storage {
        counter: u32,
        kill_switch: ContractAddress,
         #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event{
        CounterIncreased: CounterIncreased,
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[derive(Drop, starknet::Event)]
    struct CounterIncreased{
            #[key]
            counter: u32,
    }


    #[constructor]
    fn constructor(ref self: ContractState,
                    initial_counter:u32,
                    initial_kill_switch: ContractAddress,
                    initial_owner: ContractAddress
                ) {
        self.counter.write(initial_counter);
        self.kill_switch.write(initial_kill_switch);
        //  // Set the initial owner of the contract
        self.ownable.initializer(initial_owner);
    } 

    #[abi(embed_v0)]
    impl CounterContract of super::ICounter<ContractState>{
        fn get_counter(self: @ContractState) -> u32{
            self.counter.read()
        }

        // fn increase_counter(ref self:ContractState){
        //     let contract_address: ContractAddress = self.kill_switch.read();
        //     let switch: bool = IKillSwitchDispatcher { contract_address }.is_active();
        //     if !switch {self.counter.write(self.counter.read() + 1);
        //     self.emit(CounterIncreased{counter:self.counter.read()});}
        // }

        fn increase_counter(ref self:ContractState){
            self.ownable.assert_only_owner();
            let contract_address: ContractAddress = self.kill_switch.read();
            let switch: bool = IKillSwitchDispatcher { contract_address }.is_active();
            assert!(!switch, "Kill Switch is active");
            {self.counter.write(self.counter.read() + 1);
            self.emit(CounterIncreased{counter:self.counter.read()});}
        }
    }
}