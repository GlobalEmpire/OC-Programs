--This is a program created at the insistence of Inari
local input1 = 0
local input2 = 0
print("Welcome to the Great Global Empire Addition Assistant!")

while true do
	print("Please enter the first number to add.")
	input1 = io.read()
	print("Please enter the second number to add.")
	input2 = io.read()
	print("Your result is "..(input1 + input2))
end