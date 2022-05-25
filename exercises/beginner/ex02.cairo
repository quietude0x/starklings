%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_le

# I AM NOT DONE

# We want to store more info than just the `star` size.
# We are going to give them a name and a size

# TODO
# Create a `Star` stuct
# It must have two members:
# - name
# - size
# Both members are of type `felt`
# https://www.cairo-lang.org/docs/reference/syntax.html#structs

struct Star:
    member name : felt
    member size : felt
end

@storage_var
func dust(address : felt) -> (amount : felt):
end

# TODO
# Update the `star` storage to store `Star` instead of `felt`

@storage_var
func slot(address : Star) -> (slot : Star):
end

@event
func a_star_is_born(account : felt, slot : felt, size : Star):
end

@external
func collect_dust{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(amount : felt):
    let (address) = get_caller_address()

    let (res) = dust.read(address)
    dust.write(address, res + amount)

    return ()
end

# TODO
# Update the `light_star` external so it take a `Star` struct instead of the amount of dust
# Caller `dust` storage must be deducted form a amount equal to the star size

@external
func light_star{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    Star
):
    # TODO
    # Get the caller address
    let (address) = get_caller_address()
    # Get the amount on dust owned by the caller
    let (current_amount) = dust.read(address)
    # Make sure this amount is at least equal to `dust_amount`
    assert_le(dust_amount, current_amount) # i.e require(dust amount <= current_amout)
    # Get the caller next available `slot`
    let (next_available_slot) = slot.read(address)
    # Update the amount of dust owned by the caller
    dust.write(address, current_amount - dust_amount)
    # Register the newly created star, with a size equal to `dust_amount`
    star.write(address, next_available_slot, dust_amount)
    # Increment the caller next available slot
    slot.write(address, next_available_slot + 1)
    # Emit an `a_star_is_born` even with appropiate valued
    a_star_is_born.emit(address, next_available_slot, dust_amount) 
    return ()
end

@view
func view_dust{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
) -> (amount : felt):
    let (res) = dust.read(address)
    return (res)
end

@view
func view_slot{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
) -> (amount : felt):
    let (res) = slot.read(address)
    return (res)
end

# TODO
# Create a view for `star`
# It must return an instance of `Star` instead of a `felt`

#########
# TESTS #
#########

@external
func test_collect_dust{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    collect_dust(5)
    let (dust_amount) = view_dust(0)
    assert dust_amount = 5

    collect_dust(10)
    let (dust_amount) = view_dust(0)
    assert dust_amount = 15

    return ()
end

@external
func test_light_star_ok{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    collect_dust(100)
    let (dust_amount) = view_dust(0)
    assert dust_amount = 100

    # `Andromeda` encoded
    light_star(Star(0x416e64726f6d656461, 60))
    let (dust_amount) = view_dust(0)
    assert dust_amount = 40
    let (slot) = view_slot(0)
    assert slot = 1
    let (star) = view_star(0, 0)
    assert star.name = 0x416e64726f6d656461
    assert star.size = 60

    return ()
end

@external
func test_light_star_ko{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    collect_dust(100)
    let (dust_amount) = view_dust(0)
    assert dust_amount = 100

    %{ expect_revert() %}
    light_star(Star(0x416e64726f6d656461, 1000))
    let (dust_amount) = view_dust(0)
    assert dust_amount = 100
    let (slot) = view_slot(0)
    assert slot = 0

    return ()
end
