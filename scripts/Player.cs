using Godot;
using System;

public partial class Player : CharacterBody2D
{
	[Export] public float Speed = 300.0f;
	
	private AnimationPlayer _anim;
	private Vector2 _lastDirection = Vector2.Down;

	public override void _Ready()
	{
		_anim = GetNode<AnimationPlayer>("AnimationPlayer");
	}

	public override void _PhysicsProcess(double delta)
	{
		Vector2 inputDir = Input.GetVector("ui_left", "ui_right", "ui_up", "ui_down");

		if (inputDir != Vector2.Zero)
		{
			Velocity = inputDir * Speed;
			_lastDirection = inputDir;
			// Usiamo il vettore di input per decidere l'animazione
			PlayWalkingAnimation(inputDir);
		}
		else
		{
			Velocity = Vector2.Zero;
			_anim.Play("idle");
		}

		MoveAndSlide();
	}

	private void PlayWalkingAnimation(Vector2 dir)
	{
		// Otteniamo l'angolo in gradi (-180 a 180)
		float angle = Mathf.RadToDeg(dir.Angle());

		// Mappiamo l'angolo alla stringa corretta
		string animName = angle switch
		{
			>= -22.5f and <= 22.5f => "walk_e",
			> 22.5f and <= 67.5f => "walk_se",
			> 67.5f and <= 112.5f => "walk_s",
			> 112.5f and <= 157.5f => "walk_sw",
			> 157.5f or <= -157.5f => "walk_w",
			> -157.5f and <= -112.5f => "walk_nw",
			> -112.5f and <= -67.5f => "walk_n",
			> -67.5f and < -22.5f => "walk_ne",
			_ => "idle"
		};

		_anim.Play(animName);
	}
}
