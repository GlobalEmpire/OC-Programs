--This program is a tiny program designed to monitor both a IC2 Reactor
--and a optional NuclearCraft geiger counter block. IT was written by
--AshleighTheCutie.


component=require("component")

if component.isAvailable("energy_device") == false then
    print("You need at least one Reactor!")
end

while true do
    print("_____________________________")
    print("Heat Level: " .. component.energy_device.getHeat() .. " / " .. component.energy_device.getMaxHeat())
    print("Reactor IC2 Energy Output: " .. component.energy_device.getReactorEUOutput() .. " EU/t")
    if component.energy_device.getReactorEnergyOutput then
        print("Reactor RF Energy Output: " .. component.energy_device.getReactorEnergyOutput() .. " RF/t")
    end
    if component.isAvailable("nc_geiger_counter") == true then
      print("Radiation Level: " .. component.nc_geiger_counter.getChunkRadiationLevel() .. " Rads/t")
    end
    if component.energy_device.producesEnergy() == true then
        print("Reactor is ON")
    else
        print("Reactor is OFF")
    end
    print("-----------------------------")
    os.sleep(1)
end
