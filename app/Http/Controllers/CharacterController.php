<?php

namespace App\Http\Controllers;

use App\Models\Character;
use Illuminate\Http\Request;

class CharacterController extends Controller
{
    public function create(){
        return view('characters.create');
    }
    public function index(){
        $characters = Character::all();
        return view('characters.index', compact('characters'));
    }
}
